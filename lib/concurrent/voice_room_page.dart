import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'connection.dart';
import 'fps_meter.dart';
import 'funnel.dart';
import 'message_queue.dart';
import 'models.dart';
import 'parser.dart';
import 'room_bloc.dart';
import 'simulator.dart';
import 'stats.dart';
import 'widgets.dart';

/// ============================================================================
/// 语音房 · 并发消息演示页
/// ----------------------------------------------------------------------------
/// 把文章里的「四层漏斗」跑起来，并可视化每一层的水位：
///   长连接(模拟器) → ①解析(常驻 Isolate) → ②优先级队列 → ③Stream 分发 → ④UI 节流
/// 控制项：
///   - 模拟一波洪峰：瞬间灌入大量消息
///   - 自动持续推送：模拟真实房间的不间断消息流
///   - 模拟断线：触发指数退避重连，并在重连后补增量快照
///   - 重置：清空整个管道重新开始
/// ============================================================================
class VoiceRoomPage extends StatefulWidget {
  const VoiceRoomPage({super.key});

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {
  late MessageQueue _queue;
  late RoomBloc _bloc;
  late RoomConnection _conn;
  late MessageSimulator _sim;
  late ParserIsolate _parser;

  final RoomStats _stats = RoomStats();
  ConnStatus _connStatus = ConnStatus.connected;

  bool _ready = false;
  bool _disposed = false;
  bool _auto = false;

  Timer? _pumpTimer; // 调度循环：每 60ms pump 一次
  Timer? _uiTimer; // 统计刷新：每 200ms setState 一次
  int _resetToken = 0; // 重置时变化，强制子树重挂以拿到新 Stream

  @override
  void initState() {
    super.initState();
    _buildPipeline();

    // 调度循环：把不可控的消息洪峰整形成固定节奏的 UI 更新流
    _pumpTimer = Timer.periodic(
      const Duration(milliseconds: 60),
      (_) => _queue.pump(lowBudget: 8),
    );
    // 统计面板刷新（低频，不影响高频渲染路径）
    _uiTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (mounted && !_disposed) {
          _stats.queued = _queue.length;
          _stats.dispatched = _bloc.dispatched;
          _stats.dropped = _queue.dropped;
          setState(() {});
        }
      },
    );
  }

  /// 构建 / 重建整条消息管道
  void _buildPipeline() {
    _queue = MessageQueue();
    _bloc = RoomBloc(_queue);
    _conn = RoomConnection(
      onReconnect: () {
        // 重连成功后补一波增量快照
        if (!_disposed) _sim.burst(30);
      },
      onStatus: (s) {
        if (mounted) setState(() => _connStatus = s);
      },
    );
    _sim = MessageSimulator(onRaw: _onRaw);

    _ready = false;
    ParserIsolate.spawn(onParsed: _onParsed).then((p) {
      if (_disposed) {
        p.dispose();
        return;
      }
      _parser = p;
      setState(() => _ready = true);
    });
  }

  /// 模拟器产出一条原始消息（等价于 IM SDK 的 onRecvNewMessage）
  void _onRaw(String raw) {
    _stats.received++;
    // 断线期间不接收（模拟网络线程不再回调）
    if (_connStatus == ConnStatus.connected && _ready) {
      _parser.parse(raw);
    }
  }

  /// 解析 Isolate 回传结果（运行在主线程事件循环）
  void _onParsed(RoomMessage? msg) {
    if (msg == null) {
      _stats.failed++;
      return;
    }
    _stats.parsed++;
    _queue.enqueue(msg);
  }

  void _onSimulateDisconnect() {
    _conn.onDisconnected();
  }

  void _onToggleAuto() {
    setState(() => _auto = !_auto);
    if (_auto) {
      _sim.startAuto();
    } else {
      _sim.stopAuto();
    }
  }

  void _onReset() {
    _pumpTimer?.cancel();
    _uiTimer?.cancel();
    _sim.dispose();
    _bloc.dispose();
    _conn.dispose();
    _parser.dispose();

    _stats.reset();
    _connStatus = ConnStatus.connected;
    _auto = false;
    _resetToken++;

    _buildPipeline();
    _pumpTimer = Timer.periodic(
      const Duration(milliseconds: 60),
      (_) => _queue.pump(lowBudget: 8),
    );
    _uiTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (mounted && !_disposed) {
          _stats.queued = _queue.length;
          _stats.dispatched = _bloc.dispatched;
          _stats.dropped = _queue.dropped;
          setState(() {});
        }
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voiceRoomTitle),
        actions: [
          // 实时 FPS 监测：直观看出高并发下是否掉帧
          const FpsMeter(),
          const SizedBox(width: 8),
          // 连接状态指示
          Chip(
            label: Text(
              _connStatus == ConnStatus.connected
                  ? l10n.connected
                  : (_connStatus == ConnStatus.reconnecting
                      ? l10n.reconnecting
                      : l10n.disconnected),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: _connStatus == ConnStatus.connected
                ? Colors.green
                : (_connStatus == ConnStatus.reconnecting
                    ? Colors.orange
                    : Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _onSimulateDisconnect,
            icon: const Icon(Icons.wifi_off, size: 18),
            label: Text(l10n.simulateDisconnect),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            FunnelDiagram(stats: _stats, connStatus: _connStatus),
            const SizedBox(height: 10),
            // 控制按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _ready ? () => _sim.burst(150) : null,
                  icon: const Icon(Icons.flash_on),
                  label: Text(l10n.simulateBurst),
                ),
                FilledButton.tonalIcon(
                  onPressed: _ready ? _onToggleAuto : null,
                  icon: Icon(_auto ? Icons.pause : Icons.play_arrow),
                  label: Text(_auto ? l10n.stopStream : l10n.autoStream),
                ),
                OutlinedButton.icon(
                  onPressed: _onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.resetRoom),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 主体：左侧麦位+礼物，右侧公屏
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_resetToken),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(l10n.micSeats),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                // 礼物飘屏叠加在麦位区之上
                                child: Stack(
                                  children: [
                                    SeatMap(micStream: _bloc.micStream),
                                    Positioned.fill(
                                      child: GiftOverlay(
                                        giftStream: _bloc.giftStream,
                                        emptyHint: l10n.noGiftHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(l10n.publicChat),
                          Expanded(
                            child: Card(
                              child: ChatList(
                                chatStream: _bloc.chatStream,
                                onCount: (n) => _stats.chat = n,
                                emptyHint: l10n.emptyChatHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _pumpTimer?.cancel();
    _uiTimer?.cancel();
    _sim.dispose();
    _bloc.dispose();
    _conn.dispose();
    _parser.dispose();
    super.dispose();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
