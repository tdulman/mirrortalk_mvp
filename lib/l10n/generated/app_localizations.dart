import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The product name shown in app chrome and metadata.
  ///
  /// In en, this message translates to:
  /// **'MirrorTalk'**
  String get appTitle;

  /// Daily morning reminder notification title.
  ///
  /// In en, this message translates to:
  /// **'Morning focus'**
  String get morningReminderTitle;

  /// Daily morning reminder notification body.
  ///
  /// In en, this message translates to:
  /// **'What do you want to accomplish today?'**
  String get morningReminderBody;

  /// Daily evening reminder notification title.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get eveningReminderTitle;

  /// Daily evening reminder notification body.
  ///
  /// In en, this message translates to:
  /// **'What did you get done today?'**
  String get eveningReminderBody;

  /// Main Today section title on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaySectionTitle;

  /// Title for the morning self-talk ritual.
  ///
  /// In en, this message translates to:
  /// **'Morning mirror'**
  String get morningRitualTitle;

  /// Prompt shown before a morning self-talk record.
  ///
  /// In en, this message translates to:
  /// **'What will you do today, and why does it matter?'**
  String get morningRitualPrompt;

  /// Title for the evening self-talk ritual.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get eveningRitualTitle;

  /// Prompt shown before an evening self-talk record.
  ///
  /// In en, this message translates to:
  /// **'What happened today, and what can tomorrow learn from it?'**
  String get eveningRitualPrompt;

  /// Title for the weekly review ritual.
  ///
  /// In en, this message translates to:
  /// **'Weekly rewind'**
  String get weeklyRitualTitle;

  /// Prompt shown for the weekly review ritual.
  ///
  /// In en, this message translates to:
  /// **'Look back gently. What pattern is worth carrying into next week?'**
  String get weeklyRitualPrompt;

  /// Primary action to begin a self-talk record.
  ///
  /// In en, this message translates to:
  /// **'Start Mirror Talk'**
  String get startMirrorTalk;

  /// Supportive helper copy under the primary ritual action.
  ///
  /// In en, this message translates to:
  /// **'One honest minute is enough.'**
  String get oneMinuteEnough;

  /// Section label for today's goals and done states.
  ///
  /// In en, this message translates to:
  /// **'Today\'s intention'**
  String get todaysIntention;

  /// Title inside the Today Summary card.
  ///
  /// In en, this message translates to:
  /// **'Three small commitments'**
  String get summaryCardTitle;

  /// Example goal hint for the first commitment input.
  ///
  /// In en, this message translates to:
  /// **'Read 20 pages'**
  String get goalHintRead;

  /// Example goal hint for the second commitment input.
  ///
  /// In en, this message translates to:
  /// **'Send one important email'**
  String get goalHintEmail;

  /// Example goal hint for the third commitment input.
  ///
  /// In en, this message translates to:
  /// **'Take a 15-minute walk'**
  String get goalHintWalk;

  /// Button label to save today's intentions.
  ///
  /// In en, this message translates to:
  /// **'Save intention'**
  String get saveIntention;

  /// Snackbar text after saving today's intentions.
  ///
  /// In en, this message translates to:
  /// **'Intention saved'**
  String get intentionSaved;

  /// Section title for the user's recent entries.
  ///
  /// In en, this message translates to:
  /// **'Recent reflections'**
  String get recentReflections;

  /// Empty state title when there are no journal entries.
  ///
  /// In en, this message translates to:
  /// **'No reflections yet'**
  String get noReflectionsYet;

  /// Empty state helper text for the first reflection.
  ///
  /// In en, this message translates to:
  /// **'Start with one short mirror talk. Speak naturally; this is only for you.'**
  String get firstReflectionHint;

  /// Label for current streak in the calm progress strip.
  ///
  /// In en, this message translates to:
  /// **'Showing up'**
  String get showingUp;

  /// Label for best streak.
  ///
  /// In en, this message translates to:
  /// **'Best run'**
  String get bestRun;

  /// Label for weekly active days.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// Label for weekly completed goals.
  ///
  /// In en, this message translates to:
  /// **'Goals done'**
  String get goalsDone;

  /// Tooltip for the settings button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Today journal filter label.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// Week journal filter label.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get filterWeek;

  /// Month journal filter label.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get filterMonth;

  /// All journal filter label.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Title for the video recording screen.
  ///
  /// In en, this message translates to:
  /// **'Mirror Talk'**
  String get mirrorTalkTitle;

  /// Prompt shown on the video recording screen for morning.
  ///
  /// In en, this message translates to:
  /// **'Today I will... because...'**
  String get mirrorTalkPromptMorning;

  /// Prompt shown on the video recording screen for evening.
  ///
  /// In en, this message translates to:
  /// **'What happened today? What can tomorrow learn?'**
  String get mirrorTalkPromptEvening;

  /// Loading text while camera initializes.
  ///
  /// In en, this message translates to:
  /// **'Preparing your private mirror...'**
  String get mirrorTalkPreparingCamera;

  /// Error text when camera hardware is unavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get mirrorTalkNoCamera;

  /// Dialog title when video recording permissions are missing.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone access needed'**
  String get mirrorTalkPermissionTitle;

  /// Dialog body when video recording permissions are missing.
  ///
  /// In en, this message translates to:
  /// **'MirrorTalk records private videos on your device. Please allow camera and microphone access to continue.'**
  String get mirrorTalkPermissionBody;

  /// Button label to open app settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get mirrorTalkOpenSettings;

  /// Cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mirrorTalkCancel;

  /// Button label to start video recording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get mirrorTalkStartRecording;

  /// Button label to stop video recording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get mirrorTalkStopRecording;

  /// Button label to discard a recorded video and record again.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get mirrorTalkRetake;

  /// Button label to save a recorded mirror talk.
  ///
  /// In en, this message translates to:
  /// **'Save reflection'**
  String get mirrorTalkSaveReflection;

  /// Label for optional reflection transcript/note field.
  ///
  /// In en, this message translates to:
  /// **'Reflection note'**
  String get mirrorTalkTranscriptLabel;

  /// Hint for optional reflection transcript/note field.
  ///
  /// In en, this message translates to:
  /// **'Write the words you want to keep after the video fades.'**
  String get mirrorTalkTranscriptHint;

  /// Snackbar text after saving a video reflection.
  ///
  /// In en, this message translates to:
  /// **'Reflection saved'**
  String get mirrorTalkSaved;

  /// Title for the goal suggestions sheet.
  ///
  /// In en, this message translates to:
  /// **'Suggested goals'**
  String get goalSuggestionsTitle;

  /// Label for a goal suggestion text field.
  ///
  /// In en, this message translates to:
  /// **'Goal {index}'**
  String goalSuggestionLabel(int index);

  /// Button label for applying suggested goals to today's intention.
  ///
  /// In en, this message translates to:
  /// **'Apply to Today'**
  String get goalSuggestionsApply;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
