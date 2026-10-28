// ============================================================================
// 礼物工具类演示页（独立 demo）
// ----------------------------------------------------------------------------
// 直观展示 GiftManager 的规则：
//   - 小礼物合并为 xN，同屏最多 3 个
//   - 大礼物（嘉年华等）同屏只占 1 个
//   - 处理不过来的进入队列等待
// ============================================================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'gift_manager.dart';

/// 预置的小礼物
const List<Gift> _smallGifts = [
  Gift(id: 'rose', name: '玫瑰', icon: '🌹', size: GiftSize.small),
  Gift(id: 'beer', name: '啤酒', icon: '🍺', size: GiftSize.small),
  Gift(id: 'heart', name: '爱心', icon: '❤️', size: GiftSize.small),
  Gift(id: 'star', name: '星星', icon: '⭐', size: GiftSize.small),
];

/// 预置的大礼物（等级越高越稀有）
const List<Gift> _bigGifts = [
  Gift(id: 'carnival', name: '嘉年华', icon: '🎡', size: GiftSize.big, level: 5),
  Gift(id: 'rocket', name: '火箭', icon: '🚀', size: GiftSize.big, level: 3),
];

class GiftDemoPage extends StatefulWidget {
  const GiftDemoPage({super.key});

  @override
  State<GiftDemoPage> createState() => _GiftDemoPageState();
}

class _GiftDemoPageState extends State<GiftDemoPage> {
  final GiftManager _gm = GiftManager();

  @override
  void dispose() {
    _gm.dispose();
    super.dispose();
  }

  void _sendOneSmall() =>
      _gm.enqueue(_smallGifts[DateTime.now().microsecond % _smallGifts.length]);

  void _sendBurstSmall() =>
      _gm.enqueueAll(List.generate(10, (_) => _smallGifts[_randSmall()]));

  void _sendBig() => _gm.enqueue(_bigGifts[DateTime.now().microsecond % _bigGifts.length]);

  void _sendBurstBig() => _gm.enqueueAll(List.generate(3, (_) => _bigGifts[_randBig()]));

  int _randSmall() => DateTime.now().second % _smallGifts.length;
  int _randBig() => DateTime.now().second % _bigGifts.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.giftDemoTitle)),
      body: StreamBuilder<GiftState>(
        stream: _gm.stateStream,
        initialData: const GiftState(),
        builder: (context, snap) {
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 大礼物位
              _SectionTitle(label: l10n.giftBigSlot),
              _BigSlot(
                gift: s.activeBig,
                onDone: () => _gm.bigShownComplete(),
              ),
              const SizedBox(height: 16),

              // 小礼物位
              _SectionTitle(label: l10n.giftSmallSlot),
              _SmallSlots(
                items: s.visibleSmall,
                onDone: (id) => _gm.smallShownComplete(id),
              ),
              const SizedBox(height: 16),

              // 队列 + 统计
              _SectionTitle(label: l10n.giftQueueAndStats),
              _StatsCard(state: s),
              const SizedBox(height: 24),

              // 操作按钮
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _sendOneSmall,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.giftSendSmallOne),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendBurstSmall,
                    icon: const Icon(Icons.flash_on),
                    label: Text(l10n.giftSendSmallBurst),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendBig,
                    icon: const Icon(Icons.celebration),
                    label: Text(l10n.giftSendBig),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendBurstBig,
                    icon: const Icon(Icons.whatshot),
                    label: Text(l10n.giftSendBigBurst),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _gm.clear(),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.resetRoom),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

/// 大礼物槽位：一次一个
class _BigSlot extends StatelessWidget {
  const _BigSlot({this.gift, required this.onDone});
  final Gift? gift;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (gift == null) {
      return _EmptyBox(hint: AppLocalizations.of(context)!.noGiftHint);
    }
    return Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFE040FB)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(gift!.icon ?? '🎁', style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${gift!.name}（大礼物 · Lv${gift!.level}）',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('独占展示位，其余大礼物排队等待',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('播放完 →'),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// 小礼物槽位：最多 3 个，每个显示合并后的 xN
class _SmallSlots extends StatelessWidget {
  const _SmallSlots({required this.items, required this.onDone});
  final List<MergedGift> items;
  final void Function(String id) onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return _EmptyBox(hint: l10n.noGiftHint);
    }
    return Column(
      children: items
          .map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    border: Border.all(color: Colors.teal.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(m.icon ?? '🎁', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(m.label,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () => onDone(m.id),
                        child: const Text('完成 →'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(hint, style: TextStyle(color: Colors.grey.shade500)),
      );
}

/// 队列与统计
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final GiftState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow(label: l10n.giftPendingBig, value: '${state.pendingBig}'),
            _StatRow(label: l10n.giftPendingSmall,
                value: '${state.pendingSmall}（${state.pendingSmallGroups} 组）'),
            _StatRow(label: l10n.giftVisibleSmall,
                value: '${state.visibleSmallCount} / 3'),
            const Divider(),
            _StatRow(label: l10n.statReceived, value: '${state.totalReceived}'),
            _StatRow(label: l10n.giftDisplayed,
                value: '${state.totalDisplayed}'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black87)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
