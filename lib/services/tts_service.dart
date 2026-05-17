import 'package:flutter_tts/flutter_tts.dart';
import 'cloud_tts_service.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final CloudTtsService _cloudTts = CloudTtsService();
  bool _isSpeaking = false;
  bool _initialized = false;
  bool _hasNeuralVoice = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.6);

    await _selectNeuralVoice();

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);
  }

  Future<void> _selectNeuralVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;

      Map? neuralVoice;
      Map? fallbackVoice;

      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = (voice['locale'] as String?) ?? '';
        final name = (voice['name'] as String?) ?? '';
        final identifier = (voice['identifier'] as String?) ?? '';

        if (!locale.startsWith('ar')) continue;

        fallbackVoice ??= voice;

        final nameLower = name.toLowerCase();
        final idLower = identifier.toLowerCase();

        if (nameLower.contains('neural') ||
            idLower.contains('neural') ||
            nameLower.contains('network') ||
            idLower.contains('network') ||
            nameLower.contains('premium') ||
            idLower.contains('premium') ||
            nameLower.contains('high') ||
            idLower.contains('quality')) {
          neuralVoice = voice;
          break;
        }
      }

      if (neuralVoice != null) {
        await _tts.setVoice(Map<String, String>.from(neuralVoice));
        _hasNeuralVoice = true;
      } else if (fallbackVoice != null) {
        await _tts.setVoice(Map<String, String>.from(fallbackVoice));
      }
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();

    if (!_hasNeuralVoice) {
      final cloudSuccess = await _cloudTts.speak(text);
      if (cloudSuccess) return;
    }

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _cloudTts.stop();
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await stop();
    _cloudTts.dispose();
  }
}
