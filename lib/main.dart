import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'l10n/app_localizations.dart';
import 'pages/settings_page.dart';
import 'utils/dio_util.dart';
import 'utils/state_management.dart';
import 'utils/isolate_util.dart';
import 'utils/language_service.dart';
import 'concurrent/voice_room_page.dart';
import 'concurrent/gift_demo_page.dart';

/// ============================================================================
/// 主入口文件
/// ----------------------------------------------------------------------------
/// 本项目演示了以下工具类的使用：
///   1. DioUtil        —— Dio + Logger 网络请求封装
///   2. state_management —— Provider vs GetX 状态管理对比 + GetX MVVM
///   3. IsolateUtil    —— Dart Isolate 多线程使用
///   4. 国际化 (i18n)  —— flutter_localizations + gen_l10n，默认跟随系统
/// ============================================================================

Future<void> main() async {
  // 确保 Flutter 绑定初始化完成（使用 shared_preferences 等插件需要）
  WidgetsFlutterBinding.ensureInitialized();

  // 注册语言服务到 GetX，并从本地存储初始化语言
  Get.put(LanguageService());
  await LanguageService.to.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 MultiProvider 注册全局 Provider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterProvider()),
      ],
      // 根组件使用 GetMaterialApp（GetX 要求），同时也支持 Provider
      child: GetMaterialApp(
        title: 'Flutter Utils Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),

        // ====================================================================
        // 国际化配置
        // --------------------------------------------------------------------
        // localizationsDelegates：本地化代理列表
        //   - AppLocalizations.delegate         ：应用自定义文本的本地化
        //   - GlobalMaterialLocalizations.delegate ：Material 组件的本地化
        //   - GlobalWidgetsLocalizations.delegate  ：widget 库的本地化（文本方向等）
        //   - GlobalCupertinoLocalizations.delegate：Cupertino 组件的本地化
        //
        // supportedLocales：应用支持的语言列表
        //   这里使用自动生成的 AppLocalizations.supportedLocales，
        //   无需手动维护。
        //
        // 不设置 locale 属性 = 默认跟随系统语言。
        // 系统语言不在 supportedLocales 中时，自动使用第一个（英文）。
        // 语言由 LanguageService 统一管理（跟随系统 / English / 中文）。
        // ====================================================================
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomePage(),
      ),
    );
  }
}

/// 首页：展示各个工具类的入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前语言环境的本地化实例
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 设置入口
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Dio 网络请求演示 ---
          _DemoCard(
            title: l10n.dioCardTitle,
            subtitle: l10n.dioCardSubtitle,
            icon: Icons.network_check,
            color: Colors.blue,
            onTap: () => _testDioRequest(context),
          ),
          const SizedBox(height: 12),

          // --- Provider 演示 ---
          _DemoCard(
            title: l10n.providerCardTitle,
            subtitle: l10n.providerCardSubtitle,
            icon: Icons.account_tree,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProviderCounterPage()),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- GetX 演示 ---
          _DemoCard(
            title: l10n.getCardTitle,
            subtitle: l10n.getCardSubtitle,
            icon: Icons.bolt,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GetCounterPage()),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- GetX MVVM 演示 ---
          _DemoCard(
            title: l10n.mvvmCardTitle,
            subtitle: l10n.mvvmCardSubtitle,
            icon: Icons.layers,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserListPage()),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- Isolate 多线程演示 ---
          _DemoCard(
            title: l10n.isolateCardTitle,
            subtitle: l10n.isolateCardSubtitle,
            icon: Icons.linear_scale,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IsolateDemoPage()),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- 语音房高并发消息演示 ---
          _DemoCard(
            title: l10n.voiceRoomCardTitle,
            subtitle: l10n.voiceRoomCardSubtitle,
            icon: Icons.campaign,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceRoomPage()),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- 礼物工具类演示 ---
          _DemoCard(
            title: l10n.giftDemoCardTitle,
            subtitle: l10n.giftDemoCardSubtitle,
            icon: Icons.card_giftcard,
            color: Colors.pink,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GiftDemoPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 测试 Dio 网络请求
  void _testDioRequest(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      DioUtil.instance.logger.i('开始测试 Dio 网络请求...');
      // 发起 GET 请求（使用 jsonplaceholder 公共 API）
      final result = await DioUtil.instance.get('/posts/1');
      DioUtil.instance.logger.i('请求结果: $result');
      Get.snackbar(l10n.requestSuccess, l10n.dataPrintedToConsole,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(l10n.requestFailed, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

/// 演示卡片组件
class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

/// ============================================================================
/// Isolate 对比演示页面
/// ----------------------------------------------------------------------------
/// 通过一个持续旋转的加载动画作为"UI 流畅度指示器"：
///   - 点击【主线程计算】：动画会卡住不动，直到计算完成（UI 被阻塞）
///   - 点击【Isolate 计算】：动画保持流畅旋转，计算在后台完成
/// ============================================================================
class IsolateDemoPage extends StatefulWidget {
  const IsolateDemoPage({super.key});

  @override
  State<IsolateDemoPage> createState() => _IsolateDemoPageState();
}

class _IsolateDemoPageState extends State<IsolateDemoPage> {
  // 计算循环次数（调大可以让卡顿更明显，根据设备性能调整）
  static const int _loopCount = 300000000;

  String _resultText = '';
  String _costText = '';
  bool _isMainThread = false; // 区分当前是主线程还是 Isolate 计算（用于颜色）
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // 初始化默认提示文字（需要在有 context 后设置，放到 didChangeDependencies 或 build 中）
  }

  /// 主线程同步计算（会阻塞 UI，动画卡住）
  void _runOnMainThread() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isCalculating = true;
      _isMainThread = true;
      _resultText = l10n.mainThreadCalculating;
      _costText = '';
    });

    // 同步阻塞调用：直接在 UI 线程执行密集计算
    // 执行期间整个事件循环被阻塞，动画会停止
    final stopwatch = Stopwatch()..start();
    final result = IsolateUtil.heavyCalculationSync(_loopCount);
    stopwatch.stop();

    setState(() {
      _isCalculating = false;
      _resultText = l10n.calculationResult(result);
      _costText = l10n.costMainThread(stopwatch.elapsedMilliseconds);
    });
  }

  /// Isolate 计算（不阻塞 UI，动画流畅）
  Future<void> _runOnIsolate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isCalculating = true;
      _isMainThread = false;
      _resultText = l10n.isolateCalculating;
      _costText = '';
    });

    // 异步调用：计算在独立 Isolate 中执行，主线程不阻塞
    final stopwatch = Stopwatch()..start();
    final result = await IsolateUtil.heavyCalculation(_loopCount);
    stopwatch.stop();

    if (!mounted) return;
    setState(() {
      _isCalculating = false;
      _resultText = l10n.calculationResult(result);
      _costText = l10n.costIsolate(stopwatch.elapsedMilliseconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.isolateDemoTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UI 流畅度指示器：主线程被阻塞时它会停止旋转
            Text(l10n.observeAnimationHint, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 8),
            ),
            const SizedBox(height: 32),

            // 结果显示
            Text(
              _resultText.isEmpty ? l10n.tapButtonHint : _resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _costText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _isMainThread ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 40),

            // 两个对比按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCalculating ? null : _runOnMainThread,
                icon: const Icon(Icons.warning, color: Colors.red),
                label: Text(l10n.mainThreadButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCalculating ? null : _runOnIsolate,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: Text(l10n.isolateButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
