import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _listening = false;

  Future<void> _toggle() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _starting = true);

    final mic = await Permission.microphone.request();
    final speech = await Permission.speech.request();

    if (!mic.isGranted || !speech.isGranted) {
      setState(() => _starting = false);
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    final ok = await _stt.start(
      onResult: (t) => setState(() => _text = t),
      localeId: 'en_US',
    );

    setState(() {
      _starting = false;
      _listening = ok;
    });

    if (!ok && mounted) _showPermissionDialog();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone & Speech access needed'),
        content: const Text(
          'To turn your voice into text, please allow Microphone and Speech Recognition.\n\n'
          'You can enable permissions in your device settings.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _useText() => Navigator.of(context).pop(_text.trim());

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: 'Tap the mic and start speaking…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _starting ? null : _toggle,
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    label: Text(_listening
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
