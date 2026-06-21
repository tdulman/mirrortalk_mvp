// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MirrorTalk';

  @override
  String get morningReminderTitle => 'Morning focus';

  @override
  String get morningReminderBody => 'What do you want to accomplish today?';

  @override
  String get eveningReminderTitle => 'Evening check-in';

  @override
  String get eveningReminderBody => 'What did you get done today?';

  @override
  String get todaySectionTitle => 'Today';

  @override
  String get morningRitualTitle => 'Morning mirror';

  @override
  String get morningRitualPrompt =>
      'What will you do today, and why does it matter?';

  @override
  String get eveningRitualTitle => 'Evening check-in';

  @override
  String get eveningRitualPrompt =>
      'What happened today, and what can tomorrow learn from it?';

  @override
  String get weeklyRitualTitle => 'Weekly rewind';

  @override
  String get weeklyRitualPrompt =>
      'Look back gently. What pattern is worth carrying into next week?';

  @override
  String get startMirrorTalk => 'Start Mirror Talk';

  @override
  String get oneMinuteEnough => 'One honest minute is enough.';

  @override
  String get todaysIntention => 'Today\'s intention';

  @override
  String get recentReflections => 'Recent reflections';

  @override
  String get noReflectionsYet => 'No reflections yet';

  @override
  String get firstReflectionHint =>
      'Start with one short mirror talk. Speak naturally; this is only for you.';

  @override
  String get showingUp => 'Showing up';

  @override
  String get bestRun => 'Best run';

  @override
  String get thisWeek => 'This week';

  @override
  String get goalsDone => 'Goals done';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get filterToday => 'Today';

  @override
  String get filterWeek => 'Week';

  @override
  String get filterMonth => 'Month';

  @override
  String get filterAll => 'All';
}
