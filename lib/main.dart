// lib/main.dart
import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/generated/app_localizations_en.dart';
import 'screens/journal_screen.dart';
import 'services/notification_service.dart'
    show NotificationService, NotificationPlanner;
import 'services/retention_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RetentionService.enforce();

  // Notifications (Phase 5)
  await NotificationService.init();
  await NotificationService.requestPermissions();
  await NotificationPlanner.rescheduleFromPrefs();

  // Default reminders
  await NotificationService.scheduleDaily(
    id: 100,
    hour: 8,
    minute: 0,
    title: 'Morning focus',
    body: 'What do you want to accomplish today?',
  );
  await NotificationService.scheduleDaily(
    id: 101,
    hour: 20,
    minute: 0,
    title: 'Evening check-in',
    body: 'What did you get done today?',
  );

  runApp(const MirrorTalkApp());
}

class MirrorTalkApp extends StatelessWidget {
  const MirrorTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizationsEn().appTitle,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const JournalScreen(),
    );
  }
}
