import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Flutter Utils Demo'**
  String get appTitle;

  /// Title for the Dio network demo card
  ///
  /// In en, this message translates to:
  /// **'Dio + Logger Network'**
  String get dioCardTitle;

  /// Subtitle for the Dio network demo card
  ///
  /// In en, this message translates to:
  /// **'Print request URL, params and response'**
  String get dioCardSubtitle;

  /// Title for the Provider demo card
  ///
  /// In en, this message translates to:
  /// **'Provider State Management'**
  String get providerCardTitle;

  /// Subtitle for the Provider demo card
  ///
  /// In en, this message translates to:
  /// **'ChangeNotifier + context.watch'**
  String get providerCardSubtitle;

  /// Title for the GetX demo card
  ///
  /// In en, this message translates to:
  /// **'GetX State Management'**
  String get getCardTitle;

  /// Subtitle for the GetX demo card
  ///
  /// In en, this message translates to:
  /// **'GetxController + Obx reactive'**
  String get getCardSubtitle;

  /// Title for the GetX MVVM demo card
  ///
  /// In en, this message translates to:
  /// **'GetX MVVM Architecture'**
  String get mvvmCardTitle;

  /// Subtitle for the GetX MVVM demo card
  ///
  /// In en, this message translates to:
  /// **'Model - ViewModel - View layering'**
  String get mvvmCardSubtitle;

  /// Title for the Isolate demo card
  ///
  /// In en, this message translates to:
  /// **'Isolate Multithreading'**
  String get isolateCardTitle;

  /// Subtitle for the Isolate demo card
  ///
  /// In en, this message translates to:
  /// **'Compare main thread block vs Isolate smooth'**
  String get isolateCardSubtitle;

  /// Snackbar title when network request succeeds
  ///
  /// In en, this message translates to:
  /// **'Request Success'**
  String get requestSuccess;

  /// Snackbar title when network request fails
  ///
  /// In en, this message translates to:
  /// **'Request Failed'**
  String get requestFailed;

  /// Snackbar message indicating data was logged
  ///
  /// In en, this message translates to:
  /// **'Data printed to console'**
  String get dataPrintedToConsole;

  /// App bar title for the Provider counter page
  ///
  /// In en, this message translates to:
  /// **'Provider Counter'**
  String get providerCounterTitle;

  /// Label shown above the counter value
  ///
  /// In en, this message translates to:
  /// **'Current count:'**
  String get currentCount;

  /// Text on the reset button using Consumer
  ///
  /// In en, this message translates to:
  /// **'Reset (Consumer)'**
  String get resetConsumer;

  /// App bar title for the GetX counter page
  ///
  /// In en, this message translates to:
  /// **'GetX Counter'**
  String get getCounterTitle;

  /// Text on the reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// App bar title for the user list page
  ///
  /// In en, this message translates to:
  /// **'GetX MVVM - User List'**
  String get mvvmUserListTitle;

  /// Hint text when the user list is empty
  ///
  /// In en, this message translates to:
  /// **'No data, tap refresh on the top right'**
  String get noDataHint;

  /// Label showing a user's age
  ///
  /// In en, this message translates to:
  /// **'Age: {age}'**
  String ageLabel(int age);

  /// App bar title for the Isolate demo page
  ///
  /// In en, this message translates to:
  /// **'Isolate Multithreading Compare'**
  String get isolateDemoTitle;

  /// Hint text above the loading indicator
  ///
  /// In en, this message translates to:
  /// **'👇 Watch if this animation is smooth'**
  String get observeAnimationHint;

  /// Default hint text before any calculation
  ///
  /// In en, this message translates to:
  /// **'Tap a button below to start'**
  String get tapButtonHint;

  /// Status text during main thread calculation
  ///
  /// In en, this message translates to:
  /// **'Calculating on main thread... UI frozen'**
  String get mainThreadCalculating;

  /// Status text during Isolate calculation
  ///
  /// In en, this message translates to:
  /// **'Calculating on Isolate... UI stays smooth'**
  String get isolateCalculating;

  /// Text showing the calculation result
  ///
  /// In en, this message translates to:
  /// **'Result: {result}'**
  String calculationResult(int result);

  /// Cost text for main thread calculation
  ///
  /// In en, this message translates to:
  /// **'Cost: {ms} ms (main thread, UI janky)'**
  String costMainThread(int ms);

  /// Cost text for Isolate calculation
  ///
  /// In en, this message translates to:
  /// **'Cost: {ms} ms (Isolate, UI smooth)'**
  String costIsolate(int ms);

  /// Label for the main thread calculation button
  ///
  /// In en, this message translates to:
  /// **'Main Thread (UI janky)'**
  String get mainThreadButton;

  /// Label for the Isolate calculation button
  ///
  /// In en, this message translates to:
  /// **'Isolate (UI smooth)'**
  String get isolateButton;

  /// App bar title for the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section title for language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// Option to follow system language
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// Shows the current language
  ///
  /// In en, this message translates to:
  /// **'Current: {lang}'**
  String currentLanguage(String lang);

  /// Title for the voice room concurrent messages demo card
  ///
  /// In en, this message translates to:
  /// **'Voice Room: High-Concurrency Messages'**
  String get voiceRoomCardTitle;

  /// Subtitle for the voice room demo card
  ///
  /// In en, this message translates to:
  /// **'4-layer funnel: parse → queue → dispatch → throttle'**
  String get voiceRoomCardSubtitle;

  /// App bar title for the voice room page
  ///
  /// In en, this message translates to:
  /// **'Voice Room · Concurrent Messages'**
  String get voiceRoomTitle;

  /// Button to fire one message burst
  ///
  /// In en, this message translates to:
  /// **'Simulate a burst'**
  String get simulateBurst;

  /// Button to start continuous message stream
  ///
  /// In en, this message translates to:
  /// **'Auto stream'**
  String get autoStream;

  /// Button to stop the message stream
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopStream;

  /// Button to reset the room state
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetRoom;

  /// Stat: raw messages received
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statReceived;

  /// Stat: messages parsed in isolate
  ///
  /// In en, this message translates to:
  /// **'Parsed'**
  String get statParsed;

  /// Stat: messages currently queued
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statQueued;

  /// Stat: messages dispatched to UI
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get statDispatched;

  /// Stat: dropped by dedup
  ///
  /// In en, this message translates to:
  /// **'Dropped (dup)'**
  String get statDropped;

  /// Stat: chat rows on screen
  ///
  /// In en, this message translates to:
  /// **'Chat shown'**
  String get statChat;

  /// Section title for mic seats
  ///
  /// In en, this message translates to:
  /// **'Mic seats'**
  String get micSeats;

  /// Section title for gift overlay
  ///
  /// In en, this message translates to:
  /// **'Gift overlay'**
  String get giftOverlayTitle;

  /// Section title for public chat
  ///
  /// In en, this message translates to:
  /// **'Public chat'**
  String get publicChat;

  /// Connection status: connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Connection status: disconnected
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Connection status: reconnecting
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// Button to simulate connection drop
  ///
  /// In en, this message translates to:
  /// **'Simulate disconnect'**
  String get simulateDisconnect;

  /// Hint when chat list is empty
  ///
  /// In en, this message translates to:
  /// **'No messages yet — fire a burst to see the funnel work'**
  String get emptyChatHint;

  /// Hint when no gift playing
  ///
  /// In en, this message translates to:
  /// **'Gifts will fly in here'**
  String get noGiftHint;

  /// Title for the standalone gift manager demo card
  ///
  /// In en, this message translates to:
  /// **'Gift Manager (Utility)'**
  String get giftDemoCardTitle;

  /// Subtitle for the gift manager demo card
  ///
  /// In en, this message translates to:
  /// **'Small gifts xN (max 3) · big gifts (carnival) 1 at a time · rest queued'**
  String get giftDemoCardSubtitle;

  /// App bar title for the gift manager demo page
  ///
  /// In en, this message translates to:
  /// **'Gift Manager · Demo'**
  String get giftDemoTitle;

  /// Section title for the big gift slot
  ///
  /// In en, this message translates to:
  /// **'Big gift slot (1 at a time)'**
  String get giftBigSlot;

  /// Section title for the small gift slots
  ///
  /// In en, this message translates to:
  /// **'Small gift slots (max 3, merged xN)'**
  String get giftSmallSlot;

  /// Section title for queue and stats
  ///
  /// In en, this message translates to:
  /// **'Queue & stats'**
  String get giftQueueAndStats;

  /// Button to send a single small gift
  ///
  /// In en, this message translates to:
  /// **'Send 1 small'**
  String get giftSendSmallOne;

  /// Button to send 10 small gifts at once
  ///
  /// In en, this message translates to:
  /// **'Burst 10 small'**
  String get giftSendSmallBurst;

  /// Button to send a big gift (carnival)
  ///
  /// In en, this message translates to:
  /// **'Send big gift'**
  String get giftSendBig;

  /// Button to send 3 big gifts at once
  ///
  /// In en, this message translates to:
  /// **'Burst 3 big'**
  String get giftSendBigBurst;

  /// Stat: big gifts in queue
  ///
  /// In en, this message translates to:
  /// **'Big gifts waiting'**
  String get giftPendingBig;

  /// Stat: small gifts in queue
  ///
  /// In en, this message translates to:
  /// **'Small gifts waiting'**
  String get giftPendingSmall;

  /// Stat: small gifts currently shown
  ///
  /// In en, this message translates to:
  /// **'Small on screen'**
  String get giftVisibleSmall;

  /// Stat: gifts that have entered display
  ///
  /// In en, this message translates to:
  /// **'Displayed'**
  String get giftDisplayed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
