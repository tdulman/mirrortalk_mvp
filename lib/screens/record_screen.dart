// lib/screens/record_screen.dart
import 'dart:async';
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
  bool _recording = false;
  late Stopwatch _sw;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _recording = true);
    _sw.reset();
    _sw.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // ekrandaki süreyi yenile
    });
  }

  Future<void> _stopAndSave() async {
    _sw.stop();
    _ticker?.cancel();

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    final entry = Entry(
      id: id,
      type: widget.type,
      createdAt: now,
      durationSec: _sw.elapsed.inSeconds,
      transcript: '',
      tags: const [],
      videoPath: null, // ileride gerçek video yolu eklenecek
    );

    await StorageService.upsert(entry);

    if (!mounted) return;
    // Journal'a dön ve "değişti" bilgisini gönder
    Navigator.pop(context, true);
  }

  String _hhmmss() {
    final s = _sw.elapsed.inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = widget.type == RecordType.morning;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMorning ? 'Morning Talk' : 'Evening Talk'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _recording ? 'Recording...' : 'Ready',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _hhmmss(),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 32),
                if (!_recording)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _stopAndSave,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop & Save'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


