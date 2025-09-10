// lib/screens/record_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';

/// Basit kayıt ekranı (kamera yok) – dummy bir kayıt ekler.
/// AppBar başlığındaki tipe göre (sabah/akşam) kaydeder.
class RecordScreen extends StatefulWidget {
  final RecordType type;
  const RecordScreen({super.key, required this.type});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _saving = false;

  Future<void> _saveDummy() async {
    setState(() => _saving = true);
    final e = Entry(
      id: const Uuid().v4(),
      type: widget.type,
      createdAt: DateTime.now(),
      durationSec: 6,
      transcript: '',
      tags: const [],
      videoPath: null,
    );
    await StorageService.upsert(e);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.type.name} added')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == RecordType.morning
        ? 'Morning Talk'
        : 'Evening Talk';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveDummy,
          icon: const Icon(Icons.fiber_manual_record),
          label: Text(_saving ? 'Saving...' : 'Save 6s dummy entry'),
        ),
      ),
    );
  }
}

