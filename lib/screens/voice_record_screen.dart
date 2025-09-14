// lib/screens/voice_record_screen.dart
import 'package:flutter/material.dart';
import '../services/stt_service.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  State<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final _stt = SttService();
  String _text = '';
  bool _starting = false;

  Future<void> _toggle() async {
    if (_stt.isListening) {
      await _stt.stop();
      setState(() {});
      return;
    }
    setState(() => _starting = true);
    final ok = await _stt.start(
      onResult: (t) => setState(() => _text = t),
      localeId: 'en_US',
    );
    setState(() => _starting = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _useText() {
    Navigator.of(context).pop(_text.trim());
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _stt.isListening;
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: _text),
                onChanged: (v) => _text = v,
                minLines: 6,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Transcript',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _toggle,
                    icon: Icon(listening ? Icons.stop : Icons.mic),
                    label: Text(listening
                        ? 'Stop'
                        : (_starting ? 'Starting…' : 'Start Recording')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _text.trim().isEmpty ? null : _useText,
                    icon: const Icon(Icons.check),
                    label: const Text('Use Transcript'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
