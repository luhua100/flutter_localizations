import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// ============================================================================
/// Dio 网络请求工具类
/// ----------------------------------------------------------------------------
/// 功能说明：
///   基于 dio 插件封装的网络请求工具，结合 logger 插件打印完整的请求/响应日志。
///
/// 依赖插件：
///   - dio: ^5.7.0      （HTTP 网络请求库）
///   - logger: ^2.0.2+1 （日志打印库，支持彩色输出、级别过滤）
///
/// 使用方式：
///   1. 获取实例：DioUtil.instance
///   2. 发起 GET 请求：DioUtil.instance.get('/path', queryParameters: {'id': 1})
///   3. 发起 POST 请求：DioUtil.instance.post('/path', data: {'name': 'test'})
///
/// 日志打印内容：
///   - 请求方式、请求地址、请求参数（query/body）、请求头
///   - 响应状态码、响应耗时、响应数据
///   - 错误信息、堆栈跟踪
/// ============================================================================
class DioUtil {
  /// 单例实例（Dart 中通过 static final + 私有构造函数实现单例）
  static final DioUtil instance = DioUtil._internal();

  /// Dio 实例，所有网络请求都通过它发起
  late final Dio _dio;

  /// Logger 实例，用于打印彩色日志
  /// - PrettyPrinter：美化输出格式
  /// - level：日志级别，生产环境可设为 Level.warning 以减少输出
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      // 打印时不显示调用方法堆栈（避免日志过长）
      errorMethodCount: 5,
      // 错误时显示 5 行堆栈
      lineLength: 120,
      // 每行最大长度
      colors: true,
      // 启用彩色输出
      printEmojis: true,
      // 启用 emoji 图标
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      // 打印时间戳
    ),
  );

  /// 私有构造函数，防止外部直接实例化
  DioUtil._internal() {
    // 初始化 Dio 并配置全局参数
    _dio = Dio(BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      // 基础地址，实际项目中可改为环境变量或配置文件
      connectTimeout: const Duration(seconds: 15),
      // 连接超时 15 秒
      receiveTimeout: const Duration(seconds: 15),
      // 接收数据超时 15 秒
      sendTimeout: const Duration(seconds: 15),
      // 发送数据超时 15 秒
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加日志拦截器：自动打印请求和响应信息
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        // 打印请求信息
        requestHeader: true,
        // 打印请求头
        requestBody: true,
        // 打印请求体（POST 参数）
        responseHeader: false,
        // 不打印响应头（太长）
        responseBody: true,
        // 打印响应体
        error: true,
        // 打印错误信息
        logPrint: (object) {
          // 使用 logger 统一输出，替代默认的 print
          _logger.d(object.toString());
        },
      ),
    );

    // 自定义拦截器：用于打印更友好的请求摘要日志
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i(
          '🌐 发起请求\n'
          '  方式: ${options.method}\n'
          '  地址: ${options.uri}\n'
          '  参数: ${options.queryParameters}\n'
          '  数据: ${options.data}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i(
          '✅ 请求成功\n'
          '  地址: ${response.requestOptions.uri}\n'
          '  状态码: ${response.statusCode}\n'
          '  数据: ${response.data}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          '❌ 请求失败\n'
          '  地址: ${error.requestOptions.uri}\n'
          '  错误: ${error.message}\n'
          '  响应: ${error.response?.data}',
        );
        handler.next(error);
      },
    ));
  }

  /// --------------------------------------------------------------------------
  /// GET 请求
  /// --------------------------------------------------------------------------
  /// [path] 请求路径（会拼接 baseUrl）
  /// [queryParameters] URL 查询参数
  ///
  /// 使用示例：
  ///   final data = await DioUtil.instance.get('/posts/1');
  ///   print(data);
  /// --------------------------------------------------------------------------
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logger.e('GET 请求异常: $e');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------
  /// POST 请求
  /// --------------------------------------------------------------------------
  /// [path] 请求路径
  /// [data] 请求体数据（Map 会自动序列化为 JSON）
  ///
  /// 使用示例：
  ///   final data = await DioUtil.instance.post(
  ///     '/posts',
  ///     data: {'title': 'foo', 'body': 'bar'},
  ///   );
  /// --------------------------------------------------------------------------
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logger.e('POST 请求异常: $e');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------
  /// PUT 请求（更新资源）
  /// --------------------------------------------------------------------------
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logger.e('PUT 请求异常: $e');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------
  /// DELETE 请求（删除资源）
  /// --------------------------------------------------------------------------
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logger.e('DELETE 请求异常: $e');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------
  /// 下载文件
  /// --------------------------------------------------------------------------
  /// [urlPath] 下载地址
  /// [savePath] 保存到本地的路径
  ///
  /// 使用示例：
  ///   await DioUtil.instance.download(
  ///     '/files/image.png',
  ///     '/path/to/save/image.png',
  ///   );
  /// --------------------------------------------------------------------------
  Future<void> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      _logger.i('文件下载完成: $savePath');
    } catch (e) {
      _logger.e('下载失败: $e');
      rethrow;
    }
  }

  /// 暴露 Dio 实例，供高级用法（如添加自定义拦截器）
  Dio get dio => _dio;

  /// 暴露 Logger 实例，供外部打印日志
  Logger get logger => _logger;
}
