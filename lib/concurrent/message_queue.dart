import 'models.dart';

/// ============================================================================
/// ② 队列层：优先级队列削峰（最核心）
/// ----------------------------------------------------------------------------
/// 设计要点：
///   1. 入队后按 (优先级, seq) 排序，保证高优先且同优先有序
///   2. 调度循环用外部 Timer 周期触发（见 VoiceRoomPage），而非来一条处理一条
///   3. 每 tick 给低优先一个「额度」，防止聊天刷屏把麦位饿死
///   4. 入队带去重（重复 seq 直接丢弃），从源头避免重连/重试导致的重复展示
/// ============================================================================
class MessageQueue {
  MessageQueue();

  /// 调度出一条消息时回调（业务层在这里分发）
  void Function(RoomMessage)? onDispatch;

  /// 内部存储：每次 pump 前按比较器排序
  final List<RoomMessage> _list = [];

  /// 已收到的最大 seq，用于去重
  int _maxSeq = 0;

  /// 去重丢弃计数（供统计展示）
  int dropped = 0;

  int get length => _list.length;

  /// (优先级, seq) 比较器：先比优先级(数值小优先)，再比 seq(老消息先到)
  static int _compare(RoomMessage a, RoomMessage b) {
    final pa = a.priority.index;
    final pb = b.priority.index;
    if (pa != pb) return pa.compareTo(pb);
    return a.seq.compareTo(b.seq);
  }

  /// 入队：带去重（重复 seq 直接丢弃）
  void enqueue(RoomMessage msg) {
    if (msg.seq <= _maxSeq) {
      dropped++; // 重复或乱序回放，丢弃
      return;
    }
    _maxSeq = msg.seq;
    _list.add(msg);
  }

  /// 调度一次：本 tick 最多处理 [lowBudget] 条低优消息，高优不限。
  /// 把不可控的消息洪峰，整形成可控、固定节奏的 UI 更新流。
  void pump({int lowBudget = 8}) {
    if (_list.isEmpty) return;
    _list.sort(_compare); // 按优先级 + seq 排序
    int lowUsed = 0;
    while (_list.isNotEmpty) {
      final msg = _list.removeAt(0);
      if (msg.priority == Priority.low) {
        if (lowUsed >= lowBudget) {
          // 低优额度用尽，本 tick 剩下的低优消息留到下个 tick
          _list.insert(0, msg);
          break;
        }
        lowUsed++;
      }
      onDispatch?.call(msg);
    }
  }

  void clear() {
    _list.clear();
    _maxSeq = 0;
    dropped = 0;
  }
}
