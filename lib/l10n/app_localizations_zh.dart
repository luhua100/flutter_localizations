// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter 工具类演示';

  @override
  String get dioCardTitle => 'Dio + Logger 网络请求';

  @override
  String get dioCardSubtitle => '打印请求地址、参数、响应结果';

  @override
  String get providerCardTitle => 'Provider 状态管理';

  @override
  String get providerCardSubtitle => 'ChangeNotifier + context.watch';

  @override
  String get getCardTitle => 'GetX 状态管理';

  @override
  String get getCardSubtitle => 'GetxController + Obx 响应式';

  @override
  String get mvvmCardTitle => 'GetX MVVM 架构';

  @override
  String get mvvmCardSubtitle => 'Model - ViewModel - View 分层';

  @override
  String get isolateCardTitle => 'Isolate 多线程';

  @override
  String get isolateCardSubtitle => '对比主线程阻塞 vs Isolate 流畅';

  @override
  String get requestSuccess => '请求成功';

  @override
  String get requestFailed => '请求失败';

  @override
  String get dataPrintedToConsole => '数据已打印到控制台';

  @override
  String get providerCounterTitle => 'Provider 计数器';

  @override
  String get currentCount => '当前计数：';

  @override
  String get resetConsumer => '重置（Consumer 方式）';

  @override
  String get getCounterTitle => 'GetX 计数器';

  @override
  String get reset => '重置';

  @override
  String get mvvmUserListTitle => 'GetX MVVM - 用户列表';

  @override
  String get noDataHint => '暂无数据，请点击右上角刷新';

  @override
  String ageLabel(int age) {
    return '年龄: $age';
  }

  @override
  String get isolateDemoTitle => 'Isolate 多线程对比';

  @override
  String get observeAnimationHint => '👇 观察这个动画是否流畅';

  @override
  String get tapButtonHint => '点击下方按钮开始测试';

  @override
  String get mainThreadCalculating => '主线程计算中...UI 已冻结';

  @override
  String get isolateCalculating => 'Isolate 计算中...UI 保持流畅';

  @override
  String calculationResult(int result) {
    return '计算结果: $result';
  }

  @override
  String costMainThread(int ms) {
    return '耗时: $ms ms（主线程，UI 卡顿）';
  }

  @override
  String costIsolate(int ms) {
    return '耗时: $ms ms（Isolate，UI 流畅）';
  }

  @override
  String get mainThreadButton => '主线程计算（UI 会卡顿）';

  @override
  String get isolateButton => 'Isolate 计算（UI 流畅）';

  @override
  String get settingsTitle => '设置';

  @override
  String get languageSection => '语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String currentLanguage(String lang) {
    return '当前：$lang';
  }

  @override
  String get voiceRoomCardTitle => '语音房高并发消息';

  @override
  String get voiceRoomCardSubtitle => '四层漏斗：解析→队列→分发→节流';

  @override
  String get voiceRoomTitle => '语音房 · 并发消息演示';

  @override
  String get simulateBurst => '模拟一波洪峰';

  @override
  String get autoStream => '自动持续推送';

  @override
  String get stopStream => '停止';

  @override
  String get resetRoom => '重置';

  @override
  String get statReceived => '已接收';

  @override
  String get statParsed => '已解析';

  @override
  String get statQueued => '排队中';

  @override
  String get statDispatched => '已分发';

  @override
  String get statDropped => '去重丢弃';

  @override
  String get statChat => '公屏条数';

  @override
  String get micSeats => '麦位';

  @override
  String get giftOverlayTitle => '礼物飘屏';

  @override
  String get publicChat => '公屏';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '已断开';

  @override
  String get reconnecting => '重连中…';

  @override
  String get simulateDisconnect => '模拟断线';

  @override
  String get emptyChatHint => '还没有消息——点「模拟洪峰」看漏斗怎么工作';

  @override
  String get noGiftHint => '礼物会在这里飘过';

  @override
  String get giftDemoCardTitle => '礼物工具类（GiftManager）';

  @override
  String get giftDemoCardSubtitle => '小礼物合并 xN（同屏 3 个）· 大礼物（嘉年华）每次 1 个 · 其余排队';

  @override
  String get giftDemoTitle => '礼物工具类 · 演示';

  @override
  String get giftBigSlot => '大礼物位（每次 1 个）';

  @override
  String get giftSmallSlot => '小礼物位（最多 3 个，合并 xN）';

  @override
  String get giftQueueAndStats => '队列与统计';

  @override
  String get giftSendSmallOne => '发 1 个小礼物';

  @override
  String get giftSendSmallBurst => '连发 10 个小礼物';

  @override
  String get giftSendBig => '发大礼物';

  @override
  String get giftSendBigBurst => '连发 3 个大礼物';

  @override
  String get giftPendingBig => '等待中的大礼物';

  @override
  String get giftPendingSmall => '等待中的小礼物';

  @override
  String get giftVisibleSmall => '正在展示的小礼物';

  @override
  String get giftDisplayed => '已进入展示';
}
