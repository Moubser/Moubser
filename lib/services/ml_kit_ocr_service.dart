import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<String> extractTextFromPath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognisedText = await _recognizer.processImage(inputImage);
      return recognisedText.text;
    } catch (e) {
      return '';
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
