// ============================================================================
// 房间消息统一模型（语音房高并发消息处理 · 第 0 层：模型）
// ----------------------------------------------------------------------------
// 所有消息先解析成统一的 RoomMessage，用一个 type 区分，方便入队和分发。
// 使用 Dart 3 的 sealed class 做联合类型：UI 层用 switch 分发时，编译器会
// 帮你穷尽所有子类型，漏一个就编译报错。
// ============================================================================

/// 优先级：数值越小越优先（队列层据此排序）
enum Priority {
  high, // 麦位控制：上麦 / 下麦 / 控麦，必须立即响应
  middle, // 礼物：影响体验但不阻塞
  low, // 公屏 / 弹幕：量大、可延迟
}

/// 房间消息的统一抽象
sealed class RoomMessage {
  const RoomMessage({required this.seq, required this.timestamp});

  /// 服务端下发的递增序号，用于去重和排序
  final int seq;

  /// 客户端收到的时间戳
  final int timestamp;

  /// 优先级：由子类决定
  Priority get priority;
}

/// 麦位消息
final class MicMessage extends RoomMessage {
  const MicMessage({
    required super.seq,
    required super.timestamp,
    required this.action, // up / down / mute / lock
    required this.seatId,
    required this.userId,
  });

  final String action;
  final int seatId;
  final String userId;

  @override
  Priority get priority => Priority.high;
}

/// 礼物消息
final class GiftMessage extends RoomMessage {
  const GiftMessage({
    required super.seq,
    required super.timestamp,
    required this.giftId,
    required this.senderId,
    required this.combo, // 连击数，>1 时合并展示
  });

  final String giftId;
  final String senderId;
  final int combo;

  @override
  Priority get priority => Priority.middle;
}

/// 公屏聊天消息
final class ChatMessage extends RoomMessage {
  const ChatMessage({
    required super.seq,
    required super.timestamp,
    required this.userId,
    required this.text,
  });

  final String userId;
  final String text;

  @override
  Priority get priority => Priority.low;
}
