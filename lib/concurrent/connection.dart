import 'dart:async';

import 'package:flutter/foundation.dart';

/// ============================================================================
/// ⑨ 错误与重连：健壮性的底线
/// ----------------------------------------------------------------------------
/// 连接状态 + 断线自动重连（指数退避），重连成功后回调让 UI 拉取断线期间的
/// 增量快照补位，避免消息断层。
/// ============================================================================
enum ConnStatus { connected, disconnected, reconnecting }

class RoomConnection {
  RoomConnection({
    required this.onReconnect,
    required this.onStatus,
  });

  /// 重连成功后回调（用于拉取断线期间增量快照补位）
  final VoidCallback onReconnect;

  /// 连接状态变化回调（用于刷新 UI 指示）
  final void Function(ConnStatus) onStatus;

  bool _connected = true;
  int _retry = 0;
  Timer? _reconnectTimer;

  bool get connected => _connected;

  /// 网络断开（来自 IM SDK 回调）
  void onDisconnected() {
    if (!_connected) return;
    _connected = false;
    _reconnectTimer?.cancel();
    onStatus(ConnStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    // 指数退避：1s, 2s, 4s ... 最多 8s
    _retry++;
    final delay = Duration(seconds: (1 << (_retry - 1)).clamp(1, 8));
    onStatus(ConnStatus.reconnecting);
    _reconnectTimer = Timer(delay, () {
      // 模拟重连成功
      _connected = true;
      _retry = 0;
      onStatus(ConnStatus.connected);
      onReconnect(); // 重连成功后拉取增量快照补位
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
  }
}
