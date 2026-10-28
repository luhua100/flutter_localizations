import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ============================================================================
/// 轻量 FPS 监测器
/// ----------------------------------------------------------------------------
/// 用 SchedulerBinding 的「持久帧回调」统计帧数，每 [updateInterval] 计算一次
/// 平均 FPS。关键：统计回调里只累加计数、不 setState，真正的 setState 由低频
/// 定时器触发，因此监测器本身不会每帧重建，不会给被监测的页面增加渲染负担。
///
/// 颜色分级（直观看出卡顿）：
///   >= 55 FPS 绿（流畅） / 30~54 橙（一般） / < 30 红（卡顿）
/// ============================================================================
class FpsMeter extends StatefulWidget {
  const FpsMeter({
    super.key,
    this.updateInterval = const Duration(milliseconds: 500),
  });

  /// 计算 FPS 的采样窗口（默认 500ms）
  final Duration updateInterval;

  @override
  State<FpsMeter> createState() => _FpsMeterState();
}

class _FpsMeterState extends State<FpsMeter> {
  int _frames = 0;
  int _fps = 0;
  late final Stopwatch _sw;
  Timer? _timer;
  late final FrameCallback _frameCb;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    // addPersistentFrameCallback 本身就会每帧持续回调一次（无需在回调里重复注册，
    // 否则注册数会指数级翻倍，导致 _frames 被累加上亿次 → FPS 算出天文数字）。
    _frameCb = (_) {
      _frames++;
    };
    SchedulerBinding.instance.addPersistentFrameCallback(_frameCb);
    // 低频定时器：按采样窗口结算 FPS
    _timer = Timer.periodic(widget.updateInterval, _tick);
  }

  void _tick(_) {
    final elapsed = _sw.elapsedMilliseconds;
    _sw.reset();
    if (elapsed <= 0) return;
    final measured = (_frames * 1000 / elapsed).round();
    _frames = 0;
    // 空闲（无新帧）时保留上一次读数，避免闪现 0
    final fps = measured > 0 ? measured : _fps;
    if (mounted) setState(() => _fps = fps);
  }

  @override
  Widget build(BuildContext context) {
    final color = _fps >= 55
        ? Colors.green
        : (_fps >= 30 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$_fps FPS',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
