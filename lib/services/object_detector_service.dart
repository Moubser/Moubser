import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectorService {
  ObjectDetector? _detector;

  static const _arabicNames = {
    'person': 'شخص',
    'chair': 'كرسي',
    'table': 'طاولة',
    'desk': 'طاولة',
    'door': 'باب',
    'bottle': 'قنينة',
    'cup': 'كأس',
    'backpack': 'شنطة',
    'handbag': 'شنطة',
    'book': 'كتاب',
    'laptop': 'لابتوب',
    'cell phone': 'جوال',
    'tv': 'تلفزيون',
    'couch': 'كنبة',
    'sofa': 'كنبة',
    'bed': 'سرير',
    'refrigerator': 'ثلاجة',
    'oven': 'فرن',
    'sink': 'مغسلة',
    'toilet': 'حمام',
    'umbrella': 'مظلة',
    'bench': 'بنش',
    'cat': 'قطة',
    'dog': 'كلب',
    'car': 'سيارة',
    'bicycle': 'دراجة',
    'motorcycle': 'دراجة نارية',
    'bus': 'باص',
    'truck': 'شاحنة',
    'fire hydrant': 'حنفية حريق',
    'stop sign': 'لافتة وقوف',
    'parking meter': 'عداد مواقف',
    'vase': 'مزهرية',
    'potted plant': 'نبات',
    'clock': 'ساعة',
    'scissors': 'مقص',
    'teddy bear': 'دمية',
    'hair drier': 'مجفف شعر',
    'toothbrush': 'فرشاة أسنان',
  };

  static const _obstacleKeywords = [
    'person', 'chair', 'table', 'desk', 'door', 'bottle', 'cup',
    'backpack', 'handbag', 'couch', 'sofa', 'bench', 'umbrella',
    'bicycle', 'motorcycle', 'car', 'bus', 'truck', 'vase',
    'potted plant', 'fire hydrant', 'stop sign', 'tv',
  ];

  void init() {
    if (_detector != null) return;
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  Future<String> scanImage(String imagePath) async {
    init();
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final objects = await _detector!.processImage(inputImage);

      if (objects.isEmpty) return '';

      final detected = <_DetectedObstacle>[];
      for (final obj in objects) {
        final label = obj.labels.isNotEmpty ? obj.labels.first.text.toLowerCase() : '';
        if (label.isEmpty || !_obstacleKeywords.contains(label)) continue;

        final arabic = _arabicNames[label] ?? label;
        final rect = obj.boundingBox;
        final centerX = rect.left + rect.width / 2;
        final confidence = obj.labels.isNotEmpty ? obj.labels.first.confidence : 0.0;

        String position;
        if (centerX < 0.33) {
          position = 'يسار';
        } else if (centerX > 0.66) {
          position = 'يمين';
        } else {
          position = 'قبال';
        }

        if (confidence >= 0.5) {
          detected.add(_DetectedObstacle(arabic, position));
        }
      }

      return _formatResult(detected);
    } catch (e) {
      return '';
    }
  }

  String _formatResult(List<_DetectedObstacle> detected) {
    if (detected.isEmpty) return '';

    final left = detected.where((d) => d.position == 'يسار').toList();
    final right = detected.where((d) => d.position == 'يمين').toList();
    final front = detected.where((d) => d.position == 'قبال').toList();

    final parts = <String>[];
    if (front.isNotEmpty) {
      final names = front.map((d) => d.name).toSet().take(2).join(' و');
      parts.add('قدامك $names');
    }
    if (left.isNotEmpty) {
      final names = left.map((d) => d.name).toSet().take(2).join(' و');
      parts.add('على يسارك $names');
    }
    if (right.isNotEmpty) {
      final names = right.map((d) => d.name).toSet().take(2).join(' و');
      parts.add('على يمينك $names');
    }

    if (parts.isEmpty) return '';

    final result = parts.join('. ');
    final hasObstacle = detected.any((d) =>
        d.name == 'كرسي' || d.name == 'طاولة' || d.name == 'شخص' ||
        d.name == 'باب' || d.name == 'كنبة' || d.name == 'شنطة' ||
        d.name == 'قنينة');

    return hasObstacle ? 'دير بالك، $result' : result;
  }

  void dispose() {
    _detector?.close();
  }
}

class _DetectedObstacle {
  final String name;
  final String position;
  _DetectedObstacle(this.name, this.position);
}
