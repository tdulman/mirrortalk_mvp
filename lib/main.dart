// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/journal_screen.dart';

void main() {
  runApp(const MirrorTalkApp());
}

class MirrorTalkApp extends StatelessWidget {
  const MirrorTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MirrorTalk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D7A73)),
        useMaterial3: true,
      ),
      home: const JournalScreen(),
    );
  }
}
