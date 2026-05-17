import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> transcribeAudio(String filePath) async {
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3-turbo';
      request.fields['language'] = 'ar';
      request.fields['response_format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final bodyUtf8 = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = jsonDecode(bodyUtf8) as Map<String, dynamic>;
        final text = data['text'] as String? ?? '';
        return text;
      } else {
        final errorBody = response.body;
        if (response.statusCode == 401 || response.statusCode == 403) {
          return '';
        }
        if (response.statusCode == 429) {
          return '';
        }
        return '';
      }
    } catch (e) {
      return '';
    }
  }
}
