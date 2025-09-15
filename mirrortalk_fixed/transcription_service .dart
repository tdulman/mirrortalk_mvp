import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranscriptionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String> transcribe() async {
    bool available = await _speech.initialize();
    if (!available) {
      return 'Speech recognition not available';
    }

    String text = '';
    await _speech.listen(
      onResult: (result) {
        text = result.recognizedWords;
      },
    );

    // Dinlemeyi 5 saniye sonra otomatik bitir
    await Future.delayed(const Duration(seconds: 5));
    await _speech.stop();

    return text.isEmpty ? 'No speech detected' : text;
  }
}
