// ============================================================================
// 礼物工具类（语音房 · 独立工具）
// ----------------------------------------------------------------------------
// 规则：
//   - 小礼物：相同 id 自动合并为「礼物名 xN」；屏幕上最多同时显示
//     [maxSmallOnScreen] 个（默认 3）。
//   - 大礼物（如嘉年华）：每次只显示 1 个，独占大礼物位；其余排队等待。
//   - 处理不过来的礼物进入等待队列，UI 通过 [stateStream] 监听实时状态。
//
// 用法：
//   final gm = GiftManager();
//   gm.enqueue(Gift(id: 'rose', name: '玫瑰', size: GiftSize.small, icon: '🌹'));
//   gm.stateStream.listen((s) => updateUI(s));
//   // 大礼物播完：gm.bigShownComplete();
//   // 某个小礼物播完：gm.smallShownComplete(mergedId);
// ============================================================================

import 'dart:async';
import 'dart:collection';

/// 礼物尺寸
enum GiftSize {
  /// 小礼物：合并为 xN，同屏最多 3 个
  small,

  /// 大礼物（嘉年华 / 火箭等）：独占 1 个位
  big,
}

/// 一条礼物的定义
final class Gift {
  const Gift({
    required this.id,
    required this.name,
    this.icon,
    required this.size,
    this.level = 0, // 大礼物等级，越大越稀有（可用于排序展示）
  });

  final String id;
  final String name;
  final String? icon; // emoji 或资源名
  final GiftSize size;
  final int level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gift &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          size == other.size;

  @override
  int get hashCode => Object.hash(id, size);
}

/// 合并后的小礼物展示项：相同 id 累计为 count（即 xN）
final class MergedGift {
  MergedGift({required this.id, required this.name, this.icon, this.count = 1})
      : uid = '${id}_${_uidCounter++}';

  /// 进程内唯一标识，用作 UI key，避免同 id 多条礼物同屏时 Duplicate keys 崩溃
  static int _uidCounter = 0;
  final String uid;

  final String id;
  final String name;
  final String? icon;
  int count;

  void inc() => count++;

  /// 用于 UI 展示的文案，例如「玫瑰 x5」
  String get label => count > 1 ? '$name x$count' : name;
}

/// 礼物目录：把外部 giftId（如 emoji）映射成 [Gift] 定义（含尺寸/等级）。
/// 语音房里的大礼物 = 嘉年华 / 火箭 / 钻石 / 皇冠，其余默认按小礼物处理。
const Map<String, Gift> kGiftCatalog = {
  '🌹': Gift(id: 'rose', name: '玫瑰', icon: '🌹', size: GiftSize.small),
  '🎉': Gift(id: 'party', name: '庆祝', icon: '🎉', size: GiftSize.small),
  '🔥': Gift(id: 'fire', name: '火焰', icon: '🔥', size: GiftSize.small),
  '🚀': Gift(id: 'rocket', name: '火箭', icon: '🚀', size: GiftSize.big, level: 3),
  '💎': Gift(id: 'diamond', name: '钻石', icon: '💎', size: GiftSize.big, level: 4),
  '👑': Gift(id: 'crown', name: '皇冠', icon: '👑', size: GiftSize.big, level: 5),
  '🎡': Gift(id: 'carnival', name: '嘉年华', icon: '🎡', size: GiftSize.big, level: 5),
};

/// 根据外部 giftId 还原成 [Gift]；未知 id 默认当作小礼物处理。
Gift resolveGift(String giftId) =>
    kGiftCatalog[giftId] ??
    Gift(id: giftId, name: giftId, icon: giftId, size: GiftSize.small);

/// 大礼物等待项：合并后的（礼物定义 + 待展示次数）
final class _BigPending {
  _BigPending({required this.gift, required this.count});
  final Gift gift;
  int count;
}

/// 礼物管理器（纯 Dart 工具类，不依赖 Flutter）
///
/// 维护两条独立的展示通道：
///   - 大礼物通道：单槽位，按类型合并（背压），连击累计次数，超过上限丢弃多余。
///   - 小礼物通道：多槽位（默认 3），同 id 在等待队列里就先合并成 xN。
class GiftManager {
  GiftManager({this.maxSmallOnScreen = 3});

  /// 小礼物同屏最多显示数量
  final int maxSmallOnScreen;

  /// 大礼物同屏最多显示数量（固定为 1）
  static const int maxBigOnScreen = 1;

  // ---- 内部状态 ----
  // 等待中的大礼物：按 id 合并（背压），value 为待展示次数；顺序保留首次出现
  final LinkedHashMap<String, _BigPending> _bigPending = LinkedHashMap();
  // 等待中的小礼物：按 id 合并，保留首次出现顺序
  final LinkedHashMap<String, MergedGift> _smallPending = LinkedHashMap();

  // 屏幕上正在展示的
  Gift? _activeBig;
  int _activeBigRemain = 0; // 当前大礼物还需连播的次数（>0 时播完继续播同一个）
  int _activeBigToken = 0; // 每次「开始展示一个大礼物」自增，用作 UI key，
  // 避免 Flutter 复用同一个 element → AnimationController 不重播（卡死/只显示第一个）
  int _bigDropped = 0; // 超过背压上限被丢弃的大礼物数
  final List<MergedGift> _activeSmall = [];

  // 统计
  int _totalReceived = 0;
  int _totalDisplayed = 0; // 已离开队列、进入展示的礼物数

  final StreamController<GiftState> _stateController =
      StreamController<GiftState>.broadcast();

  /// 实时状态广播流，UI 订阅它刷新界面
  Stream<GiftState> get stateStream => _stateController.stream;

  // ---- 只读查询 ----
  /// 当前正在展示的大礼物（可能为 null）
  Gift? get activeBig => _activeBig;

  /// 当前正在展示的小礼物（最多 [maxSmallOnScreen] 个，已合并）
  List<MergedGift> get visibleSmall => List.unmodifiable(_activeSmall);

  /// 大礼物背压上限：合并后累计超过此数的多余大礼物直接丢弃，
  /// 防止高并发下队列无限膨胀、永远消化不完（真实场景应「限流/合并」而非无限排队）。
  static const int maxBigPending = 100;

  /// 等待中的大礼物数量（合并后的待展示次数之和）
  int get pendingBigCount =>
      _bigPending.values.fold(0, (sum, p) => sum + p.count);

  /// 等待中的大礼物类型数（按 id 去重）
  int get pendingBigGroups => _bigPending.length;

  /// 被背压丢弃的大礼物总数
  int get droppedBigCount => _bigDropped;

  /// 等待中的小礼物总数（含合并计数）
  int get pendingSmallCount =>
      _smallPending.values.fold(0, (sum, m) => sum + m.count);

  /// 等待中的小礼物分组数（按 id 去重后的类型数）
  int get pendingSmallGroups => _smallPending.length;

  /// 累计收到的礼物条数
  int get totalReceived => _totalReceived;

  /// 是否还有礼物在等待队列中
  bool get hasPending => _bigPending.isNotEmpty || _smallPending.isNotEmpty;

  // ---- 操作 ----

  /// 入队一条礼物（[count] 为连击数，会累加到合并计数里；默认 1）
  void enqueue(Gift gift, [int count = 1]) {
    assert(count >= 1, 'count must be >= 1');
    _totalReceived += count;
    if (gift.size == GiftSize.big) {
      _enqueueBig(gift, count);
    } else {
      _enqueueSmall(gift, count);
    }
    _refill();
    _notify();
  }

  /// 小礼物：先合并到「正在展示」的同类（累加连击数），否则合并进等待队列。
  /// 关键：必须同时检查「正在展示」和「等待队列」，否则同 id 同时出现在两处，
  /// UI 用同 id 作 key 时会触发 Duplicate keys 崩溃。
  void _enqueueSmall(Gift gift, int count) {
    final onScreen = _findActiveSmall(gift.id);
    if (onScreen != null) {
      onScreen.count += count;
    } else {
      final pending = _smallPending[gift.id];
      if (pending != null) {
        pending.count += count;
      } else {
        _smallPending[gift.id] = MergedGift(
          id: gift.id,
          name: gift.name,
          icon: gift.icon,
          count: count,
        );
      }
    }
  }

  /// 大礼物：按 id 合并（背压），同一类型累计连击数；超出上限的多余部分丢弃。
  void _enqueueBig(Gift gift, int count) {
    final exist = _bigPending[gift.id];
    if (exist != null) {
      exist.count += count;
    } else {
      _bigPending[gift.id] = _BigPending(gift: gift, count: count);
    }
    _enforceBigCap();
  }

  /// 背压：合并后的待展示大礼物总数超过 [maxBigPending] 时，从最晚加入的类型开始削减，
  /// 多余部分计入 [_bigDropped]（演示「高并发下要限流，而不是无限堆队列」）。
  void _enforceBigCap() {
    var total = pendingBigCount;
    while (total > maxBigPending) {
      final lastKey = _bigPending.keys.last;
      final last = _bigPending[lastKey]!;
      final over = total - maxBigPending;
      if (last.count <= over) {
        total -= last.count;
        _bigDropped += last.count;
        _bigPending.remove(lastKey);
      } else {
        last.count -= over;
        _bigDropped += over;
        total = maxBigPending;
      }
    }
  }

  /// 批量入队
  void enqueueAll(Iterable<Gift> gifts) {
    for (final g in gifts) {
      enqueue(g);
    }
  }

  /// 大礼物展示完毕（UI 在动画结束回调时调用）。
  /// - 若当前大礼物还有连播次数（[_activeBigRemain] > 0），继续播同一个（换新 token 重播动画）
  /// - 否则清空展示位并补下一个
  void bigShownComplete() {
    if (_activeBig == null) return;
    if (_activeBigRemain > 0) {
      _activeBigRemain--;
      _activeBigToken++;
    } else {
      _activeBig = null;
    }
    _refill();
    _notify();
  }

  /// 某个小礼物展示完毕（传 mergedId，即 [MergedGift.id]）
  void smallShownComplete(String mergedId) {
    _activeSmall.removeWhere((m) => m.id == mergedId);
    _refill();
    _notify();
  }

  /// 全部清空（重置）
  void clear() {
    _bigPending.clear();
    _smallPending.clear();
    _activeBig = null;
    _activeBigRemain = 0;
    _activeBigToken = 0;
    _bigDropped = 0;
    _activeSmall.clear();
    _totalReceived = 0;
    _totalDisplayed = 0;
    _notify();
  }

  /// 在「正在展示」的小礼物里查找指定 id（用于合并连击数）
  MergedGift? _findActiveSmall(String id) {
    for (final m in _activeSmall) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// 把等待队列里的礼物尽量填到展示位
  void _refill() {
    // 大礼物：位空就取一个类型（带剩余连播次数）；每次开播换新 token
    if (_activeBig == null && _bigPending.isNotEmpty) {
      final key = _bigPending.keys.first;
      final p = _bigPending.remove(key)!;
      _activeBig = p.gift;
      _activeBigRemain = p.count - 1; // 本次算 1 次，剩余连播
      _activeBigToken++;
      _totalDisplayed++;
    }
    // 小礼物：填满到 maxSmallOnScreen
    while (
        _activeSmall.length < maxSmallOnScreen && _smallPending.isNotEmpty) {
      final key = _smallPending.keys.first;
      final m = _smallPending.remove(key)!;
      _activeSmall.add(m);
      _totalDisplayed++;
    }
  }

  GiftState _snapshot() => GiftState(
        activeBig: _activeBig,
        activeBigToken: _activeBigToken,
        visibleSmall: List.of(_activeSmall),
        pendingBig: pendingBigCount,
        droppedBig: _bigDropped,
        pendingSmall: pendingSmallCount,
        pendingSmallGroups: pendingSmallGroups,
        totalReceived: _totalReceived,
        totalDisplayed: _totalDisplayed,
      );

  // 合并同一事件循环内的多次通知：高并发洪峰下避免疯狂 setState（小礼物卡顿主因）。
  bool _notifyScheduled = false;
  void _notify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    // 等当前同步代码块结束再 emit 一次最新快照
    Future.microtask(() {
      _notifyScheduled = false;
      if (!_stateController.isClosed) {
        _stateController.add(_snapshot());
      }
    });
  }

  /// 释放资源
  void dispose() => _stateController.close();
}

/// 礼物管理器在某一时刻的只读快照
final class GiftState {
  const GiftState({
    this.activeBig,
    this.activeBigToken = 0,
    this.visibleSmall = const [],
    this.pendingBig = 0,
    this.droppedBig = 0,
    this.pendingSmall = 0,
    this.pendingSmallGroups = 0,
    this.totalReceived = 0,
    this.totalDisplayed = 0,
  });

  final Gift? activeBig;
  final int activeBigToken; // 每次开播自增，UI 用其作 key，保证动画每次重播
  final List<MergedGift> visibleSmall;
  final int pendingBig;
  final int droppedBig; // 被背压丢弃的大礼物数
  final int pendingSmall;
  final int pendingSmallGroups;
  final int totalReceived;
  final int totalDisplayed;

  int get visibleSmallCount => visibleSmall.length;
  int get pendingTotal => pendingBig + pendingSmall;
}
