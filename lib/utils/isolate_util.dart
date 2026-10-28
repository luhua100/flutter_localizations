import 'dart:async';
import 'dart:isolate';
import 'package:logger/logger.dart';

/// ============================================================================
/// Dart Isolate 多线程工具类
/// ----------------------------------------------------------------------------
/// 什么是 Isolate？
///   Dart 是单线程语言，但提供了 Isolate（隔离区）来实现并发。
///   每个 Isolate 都有独立的内存空间和事件循环，彼此不共享内存，
///   只能通过消息传递（SendPort / ReceivePort）通信。
///
/// 为什么需要 Isolate？
///   当你在主线程执行耗时操作（如大文件解析、图片处理、复杂计算）时，
///   会阻塞 UI 导致卡顿。将耗时任务放到 Isolate 中执行，
///   主线程就能保持流畅。
///
/// 常见使用场景：
///   1. JSON 解析（大量数据）
///   2. 图片压缩/处理
///   3. 文件加密/解密
///   4. 复杂数学计算
///   5. 数据库批量操作
///
/// 依赖插件：
///   - logger: ^2.0.2+1（打印日志）
/// ============================================================================
class IsolateUtil {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// --------------------------------------------------------------------------
  /// 方式一：使用 Isolate.run()（Dart 2.19+ 推荐，最简单）
  /// --------------------------------------------------------------------------
  /// Isolate.run 会自动创建 Isolate、执行任务、返回结果、销毁 Isolate。
  /// 适合一次性的耗时任务。
  ///
  /// [computation] 要在 Isolate 中执行的函数（必须是顶层函数或静态方法）
  /// 返回值：函数执行的结果
  ///
  /// 使用示例：
  ///   final result = await IsolateUtil.run(() => heavyCalculation(1000000));
  /// --------------------------------------------------------------------------
  static Future<R> run<R>(FutureOr<R> Function() computation) async {
    final stopwatch = Stopwatch()..start();
    _logger.i('🚀 Isolate.run 开始执行任务...');

    try {
      final result = await Isolate.run(computation);
      stopwatch.stop();
      _logger.i('✅ Isolate.run 执行完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.e('❌ Isolate.run 执行失败: $e');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------
  /// 方式二：使用 compute()（Flutter 提供的简化版，内部基于 Isolate.run）
  /// --------------------------------------------------------------------------
  /// 注意：compute 是 Flutter 框架提供的函数（package:flutter/foundation.dart），
  /// 此处用 Isolate.run 实现等效功能，保持纯 Dart 环境可用。
  ///
  /// [callback] 要执行的函数
  /// [message] 传递给函数的参数
  ///
  /// 使用示例：
  ///   final result = await IsolateUtil.compute(parseJson, bigJsonString);
  /// --------------------------------------------------------------------------
  static Future<R> compute<M, R>(
    R Function(M message) callback,
    M message,
  ) async {
    return run(() => callback(message));
  }

  /// --------------------------------------------------------------------------
  /// 方式三：手动创建 Isolate（适合需要双向通信或长期运行的场景）
  /// --------------------------------------------------------------------------
  /// 通过 ReceivePort / SendPort 实现主线程与 Isolate 的双向通信。
  ///
  /// 使用场景：
  ///   - 需要持续发送消息给 Isolate
  ///   - Isolate 需要持续返回进度
  ///   - 需要手动管理 Isolate 生命周期
  ///
  /// [entryPoint] Isolate 入口函数（必须是顶层函数或静态方法）
  /// [initialMessage] 初始消息（通常包含 SendPort）
  /// 返回值：[Isolate 实例, ReceivePort 接收端口]
  /// --------------------------------------------------------------------------
  static Future<IsolateChannel> spawn<T>(
    void Function(SendPort) entryPoint, {
    T? initialMessage,
  }) async {
    // 主线程的接收端口，用于接收 Isolate 发回的消息
    final receivePort = ReceivePort();

    // 创建 Isolate，将主线程的 SendPort 传给它
    final isolate = await Isolate.spawn(
      entryPoint,
      receivePort.sendPort,
    );

    // 监听 Isolate 发回的第一个消息（通常是 Isolate 的 SendPort）
    final completer = Completer<SendPort>();
    late StreamSubscription subscription;
    subscription = receivePort.listen((message) {
      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
        subscription.cancel();
      }
    });

    final isolateSendPort = await completer.future;

    // 发送初始消息
    if (initialMessage != null) {
      isolateSendPort.send(initialMessage);
    }

    return IsolateChannel(
      isolate: isolate,
      receivePort: receivePort,
      sendPort: isolateSendPort,
    );
  }

  /// --------------------------------------------------------------------------
  /// 示例：在 Isolate 中解析大量 JSON
  /// --------------------------------------------------------------------------
  /// 这是一个顶层函数（必须是顶层函数或静态方法才能在 Isolate 中运行）
  ///
  /// 使用示例：
  ///   final result = await IsolateUtil.parseJsonInIsolate(jsonString);
  /// --------------------------------------------------------------------------
  static Future<dynamic> parseJsonInIsolate(String jsonString) async {
    return run(() => _parseJson(jsonString));
  }

  /// 解析 JSON 的实际逻辑（运行在 Isolate 中）
  static dynamic _parseJson(String jsonString) {
    // 这里可以使用 dart:convert 的 jsonDecode
    // 实际项目中可替换为 jsonDecode(jsonString)
    return jsonString;
  }

  /// --------------------------------------------------------------------------
  /// 示例：在 Isolate 中执行密集计算（不阻塞主线程）
  /// --------------------------------------------------------------------------
  static Future<int> heavyCalculation(int n) async {
    return run(() => _calculateSum(n));
  }

  /// --------------------------------------------------------------------------
  /// 示例：在主线程（当前线程）同步执行密集计算（会阻塞 UI）
  /// --------------------------------------------------------------------------
  /// 注意：这是同步方法，会直接阻塞调用它的线程。
  /// 如果在 UI 线程调用，界面会完全卡住直到计算完成。
  /// 用于和 [heavyCalculation] 对比，演示 Isolate 的作用。
  /// --------------------------------------------------------------------------
  static int heavyCalculationSync(int n) {
    _logger.i('⚠️ 主线程同步计算开始（UI 将会卡顿）...');
    final stopwatch = Stopwatch()..start();
    final result = _calculateSum(n);
    stopwatch.stop();
    _logger.i('⚠️ 主线程同步计算完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  /// 密集计算逻辑（可在主线程或 Isolate 中执行）
  static int _calculateSum(int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
      sum += i;
    }
    return sum;
  }
}

/// ============================================================================
/// Isolate 通信通道封装
/// ============================================================================
/// 封装了 Isolate 实例、接收端口和发送端口，方便管理双向通信。
class IsolateChannel {
  final Isolate isolate;
  final ReceivePort receivePort;
  final SendPort sendPort;

  IsolateChannel({
    required this.isolate,
    required this.receivePort,
    required this.sendPort,
  });

  /// 向 Isolate 发送消息
  void send(dynamic message) => sendPort.send(message);

  /// 监听 Isolate 发来的消息
  Stream<dynamic> get messages => receivePort;

  /// 销毁 Isolate，释放资源
  void dispose() {
    isolate.kill(priority: Isolate.immediate);
    receivePort.close();
  }
}

/// ============================================================================
/// 完整示例：双向通信的 Isolate
/// ============================================================================
///
/// 1. 定义 Isolate 入口函数（必须是顶层函数）
///
/// ```dart
/// void isolateEntry(SendPort mainSendPort) {
///   // 创建 Isolate 自己的接收端口
///   final receivePort = ReceivePort();
///
///   // 把自己的 SendPort 发给主线程
///   mainSendPort.send(receivePort.sendPort);
///
///   // 监听主线程发来的消息
///   receivePort.listen((message) {
///     print('Isolate 收到消息: $message');
///
///     // 处理消息...
///     final result = heavyWork(message);
///
///     // 把结果发回主线程
///     mainSendPort.send(result);
///   });
/// }
/// ```
///
/// 2. 在主线程中使用
///
/// ```dart
/// void main() async {
///   final channel = await IsolateUtil.spawn(isolateEntry);
///
///   // 监听 Isolate 的返回结果
///   channel.messages.listen((message) {
///     print('主线程收到结果: $message');
///   });
///
///   // 发送任务给 Isolate
///   channel.send('计算任务');
///
///   // 用完记得销毁
///   // channel.dispose();
/// }
/// ```
///
/// ============================================================================
/// 注意事项：
/// 1. Isolate 之间不共享内存，所有数据通过消息传递（拷贝）。
/// 2. 传递的对象必须是可序列化的（基本类型、List、Map 等）。
/// 3. Isolate 的入口函数必须是顶层函数或静态方法，不能是闭包或实例方法。
/// 4. 频繁创建/销毁 Isolate 有开销，长期任务建议复用。
/// 5. Flutter 中大部分 IO 操作（网络、文件）本身是异步的，
///    不需要放到 Isolate；只有 CPU 密集型任务才需要。
/// ============================================================================
