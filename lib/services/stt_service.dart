// lib/services/stt_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final _stt = stt.SpeechToText();

  Future<bool> initIfNeeded() async {
    if (_stt.isAvailable) return true;
    final available = await _stt.initialize(
      onError: (e) {},
      onStatus: (s) {},
    );
    return available;
  }

  bool get isListening => _stt.isListening;

  Future<bool> start({
    required void Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    final ok = await initIfNeeded();
    if (!ok) return false;

    final started = await _stt.listen(
      onResult: (res) => onResult(res.recognizedWords),
      partialResults: true,
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
    );

    // bazı sürümlerde listen() bool dönmez; future<void> da olabilir.
    // o durumda started null olabilir → true varsayalım:
    if (started is bool) return started;
    return true;
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
