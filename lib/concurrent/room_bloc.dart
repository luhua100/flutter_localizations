import 'dart:async';

import 'message_queue.dart';
import 'models.dart';

/// ============================================================================
/// ③ 业务层：Stream 分发，UI 只订阅「要显示的数据」
/// ----------------------------------------------------------------------------
/// 把 RoomMessage 转成各模块的「状态」，通过 StreamController 抛给 UI。
/// 铁律：消息回调里绝不 setState，只往 Stream 里 add。
/// 公屏聊天在此处做批量节流（每 80ms 抛一批），避免来一条刷一条。
/// ============================================================================
class RoomBloc {
  RoomBloc(this._queue) {
    // 队列调度出消息时，分流到不同的 Stream
    _queue.onDispatch = _handle;
    // 公屏节流：每 80ms 批量抛出当前缓冲（真正的「节流」也可放在 UI 层）
    _chatTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _flushChat(),
    );
  }

  final MessageQueue _queue;

  /// 麦位流：UI 用它更新座位图
  final _micCtrl = StreamController<MicMessage>.broadcast();

  /// 礼物流：UI 用它播动画
  final _giftCtrl = StreamController<GiftMessage>.broadcast();

  /// 公屏流：UI 用它追加聊天（批量抛）
  final _chatCtrl = StreamController<List<ChatMessage>>.broadcast();

  /// 当前公屏缓冲（节流用，攒够一批再发）
  final List<ChatMessage> _chatBuffer = [];

  Timer? _chatTimer;

  /// 已分发到 UI 的总条数（供统计展示）
  int dispatched = 0;

  Stream<MicMessage> get micStream => _micCtrl.stream;
  Stream<GiftMessage> get giftStream => _giftCtrl.stream;
  Stream<List<ChatMessage>> get chatStream => _chatCtrl.stream;

  void _handle(RoomMessage msg) {
    dispatched++;
    switch (msg) {
      case MicMessage m:
        _micCtrl.add(m); // 麦位：立即抛
      case GiftMessage g:
        _giftCtrl.add(g); // 礼物：立即抛
      case ChatMessage c:
        _chatBuffer.add(c); // 聊天：攒进缓冲，由节流逻辑批量抛
    }
  }

  void _flushChat() {
    if (_chatBuffer.isEmpty) return;
    _chatCtrl.add(_chatBuffer.toList());
    _chatBuffer.clear();
  }

  void dispose() {
    _chatTimer?.cancel();
    _micCtrl.close();
    _giftCtrl.close();
    _chatCtrl.close();
  }
}
