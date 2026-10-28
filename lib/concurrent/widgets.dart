import 'dart:async';

import 'package:flutter/material.dart';

import 'gift_manager.dart';
import 'models.dart';

/// ============================================================================
/// 语音房 UI 组件集合
///   - ChatRow / ChatList ：公屏（批量节流 + 截断 + 懒加载）
///   - GiftOverlay        ：礼物飘屏（基于 GiftManager：小礼物合并 xN/同屏 3 个，
///                          大礼物每次 1 个，剩余排队）
///   - SeatMap           ：麦位图（订阅麦位流）
/// ============================================================================

/// 单条公屏消息
class ChatRow extends StatelessWidget {
  const ChatRow({super.key, required this.msg});

  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '${msg.userId}：',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            TextSpan(text: msg.text),
          ],
        ),
      ),
    );
  }
}

/// 公屏列表：订阅 [chatStream]（已经是批量节流后的 `List<ChatMessage>`），
/// 追加时统一 setState，并只保留最近 200 条，屏幕外不构建（ListView.builder）。
class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
    required this.chatStream,
    required this.onCount,
    required this.emptyHint,
  });

  final Stream<List<ChatMessage>> chatStream;
  final void Function(int) onCount;
  final String emptyHint;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final List<ChatMessage> _items = [];
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chatStream.listen(_onBatch);
  }

  void _onBatch(List<ChatMessage> batch) {
    setState(() {
      _items.addAll(batch);
      // 只保留最近 200 条，防止无限增长拖垮性能
      if (_items.length > 200) {
        _items.removeRange(0, _items.length - 200);
      }
    });
    widget.onCount(_items.length);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Text(widget.emptyHint, style: const TextStyle(color: Colors.grey)),
      );
    }
    // ListView.builder 懒加载：屏幕外不构建
    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: _items.length,
      itemBuilder: (_, i) => ChatRow(msg: _items[i]),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }
}

/// ============================================================================
/// 礼物飘屏层（使用独立的 GiftManager 工具类）
/// ----------------------------------------------------------------------------
/// 规则由 GiftManager 统一负责：
///   - 小礼物：相同类型合并为 xN，同屏最多 3 个
///   - 大礼物（嘉年华 / 火箭等）：每次只显示 1 个，独占展示位
///   - 处理不过来的进入队列等待，播完一个自动放出下一个
/// UI 层只做两件事：把 [GiftMessage] 还原成 [Gift] 投喂给管理器，并渲染其状态快照。
/// ============================================================================

/// 礼物飘屏层：独立 Stack，不挤占麦位图。
class GiftOverlay extends StatefulWidget {
  const GiftOverlay({super.key, required this.giftStream, required this.emptyHint});

  final Stream<GiftMessage> giftStream;
  final String emptyHint;

  @override
  State<GiftOverlay> createState() => _GiftOverlayState();
}

class _GiftOverlayState extends State<GiftOverlay> {
  final GiftManager _gm = GiftManager();
  GiftState _state = const GiftState();

  @override
  void initState() {
    super.initState();
    widget.giftStream.listen(_onGift);
    _gm.stateStream.listen(_onState);
  }

  /// 漏斗里分发的礼物消息 → 还原成 Gift（含尺寸/等级）→ 投喂给 GiftManager
  void _onGift(GiftMessage g) {
    _gm.enqueue(resolveGift(g.giftId), g.combo);
  }

  void _onState(GiftState s) {
    setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final hasBig = _state.activeBig != null;
    final smalls = _state.visibleSmall;
    final hasAny = hasBig || smalls.isNotEmpty;
    return Stack(
      children: [
        if (!hasAny)
          Center(
            child: Text(
              widget.emptyHint,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        if (hasBig)
          _BigGiftWidget(
            key: ValueKey('big-${_state.activeBigToken}'),
            gift: _state.activeBig!,
            durationMs: _state.pendingBig > 3 ? 900 : 2600,
            onDone: () => _gm.bigShownComplete(),
          ),
        for (var i = 0; i < smalls.length; i++)
          _SmallGiftWidget(
            key: ValueKey(smalls[i].uid),
            merged: smalls[i],
            index: i,
            onDone: () => _gm.smallShownComplete(smalls[i].id),
          ),
        // 队列深度指示：随时显示还有多少礼物在等待，解决「不知道剩多少」的痛点
        if (_state.pendingTotal > 0 || _state.droppedBig > 0)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '排队中 · 小 ${_state.pendingSmall} · 大 ${_state.pendingBig}'
                '${_state.droppedBig > 0 ? '（丢弃${_state.droppedBig}）' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _gm.dispose();
    super.dispose();
  }
}

/// 大礼物展示：横幅样式，独占展示位，自带「弹入 + 停留 + 淡出」完整动画。
/// 动画播完（status == completed）才回调 [onDone]，由 GiftManager 放出下一个，
/// 因此绝不会卡在屏幕上。占位 key 固定为 'big'（同一时刻只会有一个大礼物）。
class _BigGiftWidget extends StatefulWidget {
  const _BigGiftWidget({
    super.key,
    required this.gift,
    required this.onDone,
    this.durationMs = 2600,
  });

  final Gift gift;
  final VoidCallback onDone;
  final int durationMs;

  @override
  State<_BigGiftWidget> createState() => _BigGiftWidgetState();
}

class _BigGiftWidgetState extends State<_BigGiftWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // 因为 key 随 activeBigToken 变化，每次开播都是全新的 element → 这里创建全新的
    // controller。积压多时由父级传入更短的 duration，加快消化。
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..forward();
    // 动画完整走完（含退场）后才通知上层释放展示位
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    const enterEnd = 0.16; // 入场占比
    const exitStart = 0.86; // 退场起点
    double opacity;
    double scale;
    if (t < enterEnd) {
      final k = t / enterEnd;
      opacity = k;
      scale = 0.6 + 0.4 * k; // 从 0.6 弹大到 1.0
    } else if (t > exitStart) {
      final k = (t - exitStart) / (1 - exitStart);
      opacity = 1 - k;
      scale = 1.0 + 0.2 * k; // 略微放大并淡出
    } else {
      opacity = 1;
      scale = 1.0;
    }
    return Positioned(
      left: 8,
      right: 8,
      top: 8,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFE040FB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Text(widget.gift.icon ?? '🎁', style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.gift.name}（大礼物 · Lv${widget.gift.level}）',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Text('独占展示位，其余大礼物排队等待',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

/// 小礼物展示：胶囊样式，按 index 向下排（最多 3 个），自动带 xN。
/// 自带「从左侧滑入 + 停留 + 向右滑出淡出」完整动画，动画播完才回调 [onDone]。
/// 位置用 [AnimatedPositioned]，当别的礼物被释放、自己的 index 变化时会平滑上移。
class _SmallGiftWidget extends StatefulWidget {
  const _SmallGiftWidget({
    super.key,
    required this.merged,
    required this.index,
    required this.onDone,
  });

  final MergedGift merged;
  final int index;
  final VoidCallback onDone;

  @override
  State<_SmallGiftWidget> createState() => _SmallGiftWidgetState();
}

class _SmallGiftWidgetState extends State<_SmallGiftWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    const enterEnd = 0.18; // 入场占比
    const exitStart = 0.82; // 退场起点
    double opacity;
    double dx;
    if (t < enterEnd) {
      final k = t / enterEnd;
      opacity = k;
      dx = -30 * (1 - k); // 从左边滑入
    } else if (t > exitStart) {
      final k = (t - exitStart) / (1 - exitStart);
      opacity = 1 - k;
      dx = 24 * k; // 向右滑出
    } else {
      opacity = 1;
      dx = 0;
    }
    final child = Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.pink.shade400,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.merged.icon ?? '🎁', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text(
                widget.merged.label, // 自动带 xN
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: 8,
      top: 84 + widget.index * 56,
      child: child,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

/// 麦位状态
class _Seat {
  _Seat();

  bool occupied = false;
  bool muted = false;
  bool locked = false;
  String userId = '';
}

/// 麦位图：订阅麦位流，按 action 更新 8 个座位的展示状态。
class SeatMap extends StatefulWidget {
  const SeatMap({super.key, required this.micStream});

  final Stream<MicMessage> micStream;

  @override
  State<SeatMap> createState() => _SeatMapState();
}

class _SeatMapState extends State<SeatMap> {
  final List<_Seat> _seats = List.generate(8, (_) => _Seat());

  @override
  void initState() {
    super.initState();
    widget.micStream.listen(_onMic);
  }

  void _onMic(MicMessage m) {
    if (m.seatId < 0 || m.seatId >= _seats.length) return;
    setState(() {
      final seat = _seats[m.seatId];
      switch (m.action) {
        case 'up':
          seat
            ..occupied = true
            ..userId = m.userId
            ..muted = false
            ..locked = false;
        case 'down':
          seat
            ..occupied = false
            ..userId = ''
            ..muted = false
            ..locked = false;
        case 'mute':
          seat.muted = true;
        case 'lock':
          seat.locked = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: _seats.length,
      itemBuilder: (_, i) {
        final s = _seats[i];
        final bg = s.locked
            ? Colors.grey.shade300
            : (s.occupied ? Colors.green.shade100 : Colors.grey.shade100);
        return Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (s.locked)
                  const Icon(Icons.lock, size: 16, color: Colors.grey)
                else if (s.occupied)
                  Text(s.muted ? '🔇' : '🎤', style: const TextStyle(fontSize: 16))
                else
                  const Text('空', style: TextStyle(color: Colors.grey)),
                if (s.occupied && s.userId.isNotEmpty)
                  Text(
                    s.userId,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
