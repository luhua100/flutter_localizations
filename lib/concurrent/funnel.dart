import 'package:flutter/material.dart';

import 'connection.dart';
import 'stats.dart';

/// ============================================================================
/// 四层漏斗示意图：把文章里的架构画成可见的实时水位
///   长连接 → ①解析(Isolate) → ②优先级队列 → ③Stream分发 → ④UI节流
/// ============================================================================
class FunnelDiagram extends StatelessWidget {
  const FunnelDiagram({
    super.key,
    required this.stats,
    required this.connStatus,
  });

  final RoomStats stats;
  final ConnStatus connStatus;

  @override
  Widget build(BuildContext context) {
    final connColor = switch (connStatus) {
      ConnStatus.connected => Colors.green,
      ConnStatus.reconnecting => Colors.orange,
      ConnStatus.disconnected => Colors.red,
    };
    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // 长连接 / 连接状态
            _Node(
              label: '长连接',
              sub: _connText(),
              value: stats.received,
              color: connColor,
            ),
            _Arrow(),
            // ① 解析
            _Node(
              label: '①解析 Isolate',
              sub: '失败 ${stats.failed}',
              value: stats.parsed,
              color: Colors.blue,
            ),
            _Arrow(),
            // ② 优先级队列
            _Node(
              label: '②优先级队列',
              sub: '丢弃 ${stats.dropped}',
              value: stats.queued,
              color: Colors.orange,
            ),
            _Arrow(),
            // ③ Stream 分发
            _Node(
              label: '③Stream 分发',
              sub: '',
              value: stats.dispatched,
              color: Colors.purple,
            ),
            _Arrow(),
            // ④ UI 节流
            _Node(
              label: '④UI 节流',
              sub: '公屏 ${stats.chat}',
              value: stats.chat,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  String _connText() {
    return switch (connStatus) {
      ConnStatus.connected => '已连接',
      ConnStatus.reconnecting => '重连中',
      ConnStatus.disconnected => '已断开',
    };
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
  });

  final String label;
  final String sub;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (sub.isNotEmpty)
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
    );
  }
}
