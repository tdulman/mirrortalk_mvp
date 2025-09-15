// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/journal_screen.dart';
import 'services/notification_service.dart' show NotificationService, NotificationPlanner;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'MirrorTalk',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF224231),
      ),
      home: const JournalScreen(),
    );
  }
}



