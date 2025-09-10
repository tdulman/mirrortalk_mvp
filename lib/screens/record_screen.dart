// lib/screens/record_screen.dart
import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';

class RecordScreen extends StatefulWidget {
  final RecordType type;
  const RecordScreen({super.key, required this.type});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _saving = false;

  Future<void> _saveFakeEntry() async {
    setState(() => _saving = true);
    // Basit bir demo kaydı oluşturuyoruz (gerçek kayıt yerine)
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final e = Entry(
      id: id,
      type: widget.type,
      createdAt: DateTime.now(),
      durationSec: 6, // örnek
      transcript: null,
      tags: const [],
      videoPath: null,
    );
    await StorageService.upsert(e);
    if (mounted) {
      Navigator.pop(context, true); // Listeyi yenilemek için true dön
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == RecordType.morning ? 'Morning Talk' : 'Evening Talk';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: _saving
            ? const CircularProgressIndicator()
            : FilledButton(
                onPressed: _saveFakeEntry,
                child: const Text('Save demo entry'),
              ),
      ),
    );
  }
}



