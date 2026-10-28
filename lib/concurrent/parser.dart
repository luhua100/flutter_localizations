import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'models.dart';

/// ============================================================================
/// ① 解析层：用 Isolate 把「解码」搬离 UI 线程
/// ----------------------------------------------------------------------------
/// 大消息量下，JSON 解析本身也会卡 UI。Dart 是单线程，必须靠 Isolate。
/// 这里提供两部分：
///   1. [parseInIsolate]：纯函数，把原始字符串解析成 [RoomMessage]（失败返回 null）
///   2. [ParserIsolate]：常驻解析 Isolate（替代频繁 compute），消息通过 SendPort 来回传
/// ============================================================================

/// 后台解析函数（Isolate 要求顶层或静态函数）
/// 收到原始字符串，解析成 RoomMessage，失败返回 null（直接丢弃，不崩 UI）
RoomMessage? parseInIsolate(String raw) {
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _toMessage(json);
  } catch (_) {
    return null; // 解析失败的消息直接丢弃
  }
}

RoomMessage? _toMessage(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? '';
  switch (type) {
    case 'mic':
      return MicMessage(
        seq: _asInt(json['seq']),
        timestamp: _asInt(json['ts']),
        action: json['action'] as String? ?? '',
        seatId: _asInt(json['seatId']),
        userId: json['userId'] as String? ?? '',
      );
    case 'gift':
      return GiftMessage(
        seq: _asInt(json['seq']),
        timestamp: _asInt(json['ts']),
        giftId: json['giftId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        combo: _asInt(json['combo']),
      );
    case 'chat':
      return ChatMessage(
        seq: _asInt(json['seq']),
        timestamp: _asInt(json['ts']),
        userId: json['userId'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
    default:
      return null; // 未知类型丢弃
  }
}

/// 容错取值：服务端字段可能缺失 / 类型不对，统一兜底，避免强转崩溃
int _asInt(dynamic v) => v is int ? v : (int.tryParse('$v') ?? 0);

/// 常驻解析 Isolate：启动时建好，消息通过 SendPort 来回传。
/// 避免高频 compute 反复创建 / 销毁 Isolate 的开销。
class ParserIsolate {
  ParserIsolate._(this._isolate, this._receivePort, this._onParsed);

  final Isolate _isolate;
  final ReceivePort _receivePort;
  final void Function(RoomMessage?) _onParsed;

  SendPort? _parserSendPort;
  bool _handshakeDone = false;

  /// 创建并启动常驻解析 Isolate。
  /// [onParsed] 在**主线程**事件循环中被回调，参数为解析结果（null = 解析失败）。
  static Future<ParserIsolate> spawn({
    required void Function(RoomMessage?) onParsed,
  }) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_entry, receivePort.sendPort);
    final parser = ParserIsolate._(isolate, receivePort, onParsed);
    parser._receivePort.listen((message) {
      if (!parser._handshakeDone) {
        // 第一条消息是解析 Isolate 回传的「入站 SendPort」
        parser._parserSendPort = message as SendPort;
        parser._handshakeDone = true;
        return;
      }
      // 之后每条都是解析结果（可能为 null = 解析失败）
      parser._onParsed(message as RoomMessage?);
    });
    return parser;
  }

  /// 提交一条原始消息去解析（握手完成前调用会被忽略）
  void parse(String raw) {
    _parserSendPort?.send(raw);
  }

  /// 解析 Isolate 入口（必须顶层函数）
  static void _entry(SendPort mainSendPort) {
    final inPort = ReceivePort();
    mainSendPort.send(inPort.sendPort); // 把「入站端口」回传给主线程
    inPort.listen((raw) {
      final msg = parseInIsolate(raw as String);
      mainSendPort.send(msg); // 只回传解析结果（失败为 null）
    });
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }
}
