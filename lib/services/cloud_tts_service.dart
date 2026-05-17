import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class CloudTtsService {
  final AudioPlayer _player = AudioPlayer();

  Future<bool> speak(String text) async {
    if (text.isEmpty) return false;

    try {
      final chunks = _chunkText(text, 200);
      final tempDir = Directory.systemTemp;

      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        final tempFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}_$i.mp3');

        final uri = Uri.parse(
          'https://translate.google.com/translate_tts?ie=UTF-8&tl=ar-SA&client=tw-ob&q=${Uri.encodeComponent(chunk)}',
        );

        final response = await http.get(uri);
        if (response.statusCode != 200) continue;

        await tempFile.writeAsBytes(response.bodyBytes);
        await _player.setFilePath(tempFile.path);
        await _player.play();

        await _player.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  List<String> _chunkText(String text, int maxLen) {
    if (text.length <= maxLen) return [text];
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'[.،؛!\?\n]'));
    String current = '';
    for (final sentence in sentences) {
      if ((current + sentence).length <= maxLen) {
        current += sentence;
      } else {
        if (current.isNotEmpty) chunks.add(current);
        current = sentence;
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
