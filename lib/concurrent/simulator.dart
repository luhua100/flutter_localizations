import 'dart:async';
import 'dart:convert';
import 'dart:math';

/// ============================================================================
/// 消息模拟器：模拟语音房长连接（WebSocket / IM SDK）
/// ----------------------------------------------------------------------------
/// 持续产生原始 JSON 消息字节（字符串）。真实项目中，这来自 IM SDK 的
/// onRecvNewMessage 回调（发生在**网络线程**，回调里绝对不能直接 setState）。
/// 这里故意混入少量脏数据 / 重复 seq，用来验证「解析容错」与「去重」。
/// ============================================================================
class MessageSimulator {
  MessageSimulator({required this.onRaw});

  /// 每产生一条原始消息就回调（对齐 IM SDK 的收消息钩子）
  final void Function(String raw) onRaw;

  int _seq = 0;
  final _rng = Random();
  Timer? _autoTimer;

  static const List<String> _users = [
    '小鹿',
    '阿强',
    'Mia',
    '老王',
    'Coco',
    '游客233',
    'Bot',
  ];

  static const List<String> _chatTexts = [
    '大家好～',
    '这歌好听',
    '前排',
    '主播声音绝了',
    '哈哈哈哈',
    '蹲一个连麦',
    '欢迎新朋友',
    '666',
    '求背景音乐名字',
    '刚来 发生了什么',
    '稳住 别慌',
    '冲冲冲',
  ];

  static const List<String> _gifts = ['🌹', '🚀', '💎', '🎉', '👑', '🔥', '🎡'];

  /// 生成一条原始消息（含少量重复 seq 以测试去重）
  String _makeOne({bool forceDup = false}) {
    // 概率分布：聊天最多（低优先），礼物次之（中优先），麦位偶尔（高优先）
    final roll = _rng.nextDouble();
    final seq = forceDup ? (_seq - 1) : (++_seq);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> json;
    if (roll < 0.75) {
      json = {
        'type': 'chat',
        'seq': seq,
        'ts': ts,
        'userId': _users[_rng.nextInt(_users.length)],
        'text': _chatTexts[_rng.nextInt(_chatTexts.length)],
      };
    } else if (roll < 0.93) {
      json = {
        'type': 'gift',
        'seq': seq,
        'ts': ts,
        'giftId': _gifts[_rng.nextInt(_gifts.length)],
        'senderId': _users[_rng.nextInt(_users.length)],
        'combo': 1 + _rng.nextInt(9),
      };
    } else {
      final actions = ['up', 'down', 'mute', 'lock'];
      json = {
        'type': 'mic',
        'seq': seq,
        'ts': ts,
        'action': actions[_rng.nextInt(actions.length)],
        'seatId': _rng.nextInt(8),
        'userId': _users[_rng.nextInt(_users.length)],
      };
    }
    return jsonEncode(json);
  }

  /// 模拟一波洪峰：瞬间产生 n 条消息（含 ~5% 重复 seq）
  void burst(int n) {
    for (var i = 0; i < n; i++) {
      final dup = _rng.nextDouble() < 0.05 && _seq > 1;
      onRaw(_makeOne(forceDup: dup));
    }
  }

  /// 开始自动持续推送：每隔 [intervalMs] 来一条，偶尔成批（小洪峰）
  void startAuto({int intervalMs = 50}) {
    stopAuto();
    _autoTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_rng.nextDouble() < 0.15) {
        burst(5 + _rng.nextInt(15)); // 偶发小洪峰
      } else {
        onRaw(_makeOne());
      }
    });
  }

  void stopAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  bool get isAuto => _autoTimer?.isActive ?? false;

  void dispose() {
    stopAuto();
  }
}
