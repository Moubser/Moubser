import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'local_vision_service.dart';

class AiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  GenerativeModel? _model;
  GenerativeModel? _visionModel;
  final _localVision = LocalVisionService();

  void init() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
    _localVision.init();
  }

  Future<String> analyzeScene(Uint8List imageBytes) async {
    final local = await _localVision.analyzeLocally(imageBytes);
    if (local != null) return local;

    if (_visionModel == null) init();

    try {
      final prompt = '''
أنت صاحب كفيف وبتمشي معاه عشان تدله. احكي معاه بلهجة سعودية عامية مريحة وبسيطة.
ركز منيح بالصورة: في كراسي؟ طاولات؟ أبواب؟ مغاسل؟ ناس؟ 
إذا في أي عائق، احكيله مكانه بسرعة، مثلاً: "دير بالك في كرسي على يمينك"، "قدامك باب مسكر"، "في مغسلة على شمالك".
وإذا الطريق فاضية وما في اشي، احكيله: "طريقك سالك توكل على الله".
الرد لازم يكون جملة وحدة قصيرة جداً ومباشرة وبدون فصحى معقدة.
''';
      
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      
      final response = await _visionModel!.generateContent(content);
      return response.text ?? 'طريقك سالك توكل على الله';
    } catch (e) {
      final errorMsg = e.toString();
      print('AI Vision Error: $errorMsg');
      if (errorMsg.contains('SocketException') || errorMsg.contains('network')) {
        return 'لا يوجد اتصال بالإنترنت';
      } else if (errorMsg.contains('quota') || errorMsg.contains('429') || errorMsg.contains('RATE_LIMIT')) {
        return 'تم استنفاد الحد المسموح به للذكاء الاصطناعي';
      } else if (errorMsg.contains('API_KEY_INVALID') || errorMsg.contains('API key not valid') || errorMsg.contains('API_KEY_SERVICE_DISABLED') || errorMsg.contains('PERMISSION_DENIED') || errorMsg.contains('not found')) {
        return 'مفتاح الذكاء الاصطناعي غير صالح';
      }
      return 'خطأ: $errorMsg';
    }
  }

  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    if (_visionModel == null) init();

    try {
      final prompt = 'استخرج جميع النصوص المكتوبة في هذه الصورة بدقة وبنفس اللغة المكتوبة فيها.';
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      final response = await _visionModel!.generateContent(content);
      return response.text ?? 'لم يتم العثور على نص';
    } catch (e) {
      return 'حدث خطأ أثناء استخراج النص: $e';
    }
  }

  Future<String> summarizeText(String transcript) async {
    if (_model == null) init();

    try {
      final prompt = '''
أنت مساعد أكاديمي ذكي. قم بتلخيص النص التالي من محاضرة جامعية.
اكتب الملخص بالعربية بشكل مرتب ومختصر مع النقاط الرئيسية:

$transcript
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'لم يتم إنشاء ملخص';
    } catch (e) {
      return 'حدث خطأ أثناء إنشاء الملخص: $e';
    }
  }

  Future<String> answerQuestion(String question, String context) async {
    if (_model == null) init();

    try {
      final prompt = '''
بناءً على المحتوى التالي من المحاضرة، أجب عن السؤال:

المحتوى:
$context

السؤال: $question

أجب بالعربية بشكل واضح ومختصر:
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'لم يتم العثور على إجابة';
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }
}
