import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class LocalVisionService {
  ImageLabeler? _labeler;

  void init() {
    if (_labeler != null) return;
    final options = ImageLabelerOptions(
      confidenceThreshold: 0.6,
    );
    _labeler = ImageLabeler(options: options);
  }

  static const _obstacleMap = {
    'Chair': 'كرسي',
    'Table': 'طاولة',
    'Desk': 'طاولة',
    'Person': 'شخص',
    'People': 'ناس',
    'Door': 'باب',
    'Stairs': 'درج',
    'Staircase': 'درج',
    'Sink': 'مغسلة',
    'Window': 'شباك',
    'Cabinet': 'دولاب',
    'Shelf': 'رف',
    'Couch': 'كنبة',
    'Sofa': 'كنبة',
    'Bench': 'بنش',
    'Pillar': 'عمود',
    'Column': 'عمود',
    'Wall': 'جدار',
    'Railing': 'درابزين',
    'Fence': 'سياج',
    'Trash': 'زبالة',
    'Bicycle': 'دراجة',
    'Bag': 'شنطة',
    'Backpack': 'شنطة',
    'Bottle': 'قنينة',
    'Cup': 'كأس',
    'Fire extinguisher': 'طفاية حريق',
    'Car': 'سيارة',
    'Bus': 'باص',
    'Sign': 'لافتة',
    'Wheelchair': 'كرسي متحرك',
  };

  Future<String?> analyzeLocally(Uint8List imageBytes) async {
    init();

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/vision_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    final inputImage = InputImage.fromFile(tempFile);

    final labels = await _labeler!.processImage(inputImage);

    await tempFile.delete();

    final detected = <String>{};
    for (final label in labels) {
      final text = label.label;
      final confidence = label.confidence;
      final arabic = _obstacleMap[text];
      if (arabic != null && confidence >= 0.5) {
        detected.add(arabic);
      }
    }

    if (detected.isEmpty) return null;

    final hasObstacle = detected.any((d) =>
        d == 'كرسي' || d == 'طاولة' || d == 'شخص' || d == 'ناس' ||
        d == 'باب' || d == 'درج' || d == 'كنبة' || d == 'عمود' ||
        d == 'زبالة' || d == 'كرسي متحرك' || d == 'شنطة' ||
        d == 'قنينة' || d == 'كأس');

    if (!hasObstacle) return null;

    final list = detected.toList();
    String result;
    if (list.length == 1) {
      result = 'في ${list[0]}';
    } else if (list.length == 2) {
      result = 'في ${list[0]} و${list[1]}';
    } else {
      result = 'في ${list[0]} و${list[1]} و${list[2]}';
    }

    if (list.any((d) => d == 'كرسي' || d == 'طاولة' || d == 'كنبة')) {
      result = 'دير بالك، $result';
    }

    if (list.length >= 3) {
      result = 'الطريق مش سالك. $result';
    }

    return result;
  }

  void dispose() {
    _labeler?.close();
  }
}
