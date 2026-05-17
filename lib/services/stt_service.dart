import 'dart:io';
import 'package:record/record.dart';
import 'groq_service.dart';

class SttService {
  final GroqService _groqService = GroqService();
  Record? _recorder;
  bool _isListening = false;
  bool _isInitialized = false;
  String? _currentFilePath;

  Function(String text, bool isFinal)? _onResult;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) return true;
    _recorder = Record();
    final hasPermission = await _recorder!.hasPermission();
    _isInitialized = hasPermission;
    return hasPermission;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    bool continuous = true,
  }) async {
    if (_recorder == null) await init();
    if (_recorder == null) return;

    _onResult = onResult;
    _isListening = true;

    final dir = Directory.systemTemp;
    _currentFilePath = '${dir.path}/moubser_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder!.start(
      path: _currentFilePath!,
      encoder: AudioEncoder.wav,
      samplingRate: 16000,
      numChannels: 1,
    );
  }

  Future<String> stopListening() async {
    _isListening = false;
    try {
      final path = await _recorder?.stop();
      if (path != null) _currentFilePath = path;
    } catch (_) {}

    if (_currentFilePath == null) return '';

    final text = await _groqService.transcribeAudio(_currentFilePath!);

    try {
      File(_currentFilePath!).delete();
    } catch (_) {}

    _currentFilePath = null;
    _onResult?.call(text, true);
    return text;
  }

  void dispose() {
    _recorder?.dispose();
  }
}
