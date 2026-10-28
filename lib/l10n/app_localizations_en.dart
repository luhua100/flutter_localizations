// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Utils Demo';

  @override
  String get dioCardTitle => 'Dio + Logger Network';

  @override
  String get dioCardSubtitle => 'Print request URL, params and response';

  @override
  String get providerCardTitle => 'Provider State Management';

  @override
  String get providerCardSubtitle => 'ChangeNotifier + context.watch';

  @override
  String get getCardTitle => 'GetX State Management';

  @override
  String get getCardSubtitle => 'GetxController + Obx reactive';

  @override
  String get mvvmCardTitle => 'GetX MVVM Architecture';

  @override
  String get mvvmCardSubtitle => 'Model - ViewModel - View layering';

  @override
  String get isolateCardTitle => 'Isolate Multithreading';

  @override
  String get isolateCardSubtitle =>
      'Compare main thread block vs Isolate smooth';

  @override
  String get requestSuccess => 'Request Success';

  @override
  String get requestFailed => 'Request Failed';

  @override
  String get dataPrintedToConsole => 'Data printed to console';

  @override
  String get providerCounterTitle => 'Provider Counter';

  @override
  String get currentCount => 'Current count:';

  @override
  String get resetConsumer => 'Reset (Consumer)';

  @override
  String get getCounterTitle => 'GetX Counter';

  @override
  String get reset => 'Reset';

  @override
  String get mvvmUserListTitle => 'GetX MVVM - User List';

  @override
  String get noDataHint => 'No data, tap refresh on the top right';

  @override
  String ageLabel(int age) {
    return 'Age: $age';
  }

  @override
  String get isolateDemoTitle => 'Isolate Multithreading Compare';

  @override
  String get observeAnimationHint => '👇 Watch if this animation is smooth';

  @override
  String get tapButtonHint => 'Tap a button below to start';

  @override
  String get mainThreadCalculating => 'Calculating on main thread... UI frozen';

  @override
  String get isolateCalculating => 'Calculating on Isolate... UI stays smooth';

  @override
  String calculationResult(int result) {
    return 'Result: $result';
  }

  @override
  String costMainThread(int ms) {
    return 'Cost: $ms ms (main thread, UI janky)';
  }

  @override
  String costIsolate(int ms) {
    return 'Cost: $ms ms (Isolate, UI smooth)';
  }

  @override
  String get mainThreadButton => 'Main Thread (UI janky)';

  @override
  String get isolateButton => 'Isolate (UI smooth)';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSection => 'Language';

  @override
  String get followSystem => 'Follow System';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String currentLanguage(String lang) {
    return 'Current: $lang';
  }

  @override
  String get voiceRoomCardTitle => 'Voice Room: High-Concurrency Messages';

  @override
  String get voiceRoomCardSubtitle =>
      '4-layer funnel: parse → queue → dispatch → throttle';

  @override
  String get voiceRoomTitle => 'Voice Room · Concurrent Messages';

  @override
  String get simulateBurst => 'Simulate a burst';

  @override
  String get autoStream => 'Auto stream';

  @override
  String get stopStream => 'Stop';

  @override
  String get resetRoom => 'Reset';

  @override
  String get statReceived => 'Received';

  @override
  String get statParsed => 'Parsed';

  @override
  String get statQueued => 'Queued';

  @override
  String get statDispatched => 'Dispatched';

  @override
  String get statDropped => 'Dropped (dup)';

  @override
  String get statChat => 'Chat shown';

  @override
  String get micSeats => 'Mic seats';

  @override
  String get giftOverlayTitle => 'Gift overlay';

  @override
  String get publicChat => 'Public chat';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get simulateDisconnect => 'Simulate disconnect';

  @override
  String get emptyChatHint =>
      'No messages yet — fire a burst to see the funnel work';

  @override
  String get noGiftHint => 'Gifts will fly in here';

  @override
  String get giftDemoCardTitle => 'Gift Manager (Utility)';

  @override
  String get giftDemoCardSubtitle =>
      'Small gifts xN (max 3) · big gifts (carnival) 1 at a time · rest queued';

  @override
  String get giftDemoTitle => 'Gift Manager · Demo';

  @override
  String get giftBigSlot => 'Big gift slot (1 at a time)';

  @override
  String get giftSmallSlot => 'Small gift slots (max 3, merged xN)';

  @override
  String get giftQueueAndStats => 'Queue & stats';

  @override
  String get giftSendSmallOne => 'Send 1 small';

  @override
  String get giftSendSmallBurst => 'Burst 10 small';

  @override
  String get giftSendBig => 'Send big gift';

  @override
  String get giftSendBigBurst => 'Burst 3 big';

  @override
  String get giftPendingBig => 'Big gifts waiting';

  @override
  String get giftPendingSmall => 'Small gifts waiting';

  @override
  String get giftVisibleSmall => 'Small on screen';

  @override
  String get giftDisplayed => 'Displayed';
}
