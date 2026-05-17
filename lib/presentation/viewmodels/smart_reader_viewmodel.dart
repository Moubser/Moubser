import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'base_viewmodel.dart';
import '../../services/stt_service.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../../services/ml_kit_ocr_service.dart';
import '../../di/locator.dart';

class SmartReaderViewModel extends BaseViewModel {
  final SttService _sttService = SttService();
  final AiService _aiService = locator<AiService>();
  final TtsService _ttsService = locator<TtsService>();
  final MlKitOcrService _ocrService = MlKitOcrService();

  ScaffoldMessengerState? scaffoldMessenger;

  String _transcript = '';
  String get transcript => _transcript;

  String _summary = '';
  String get summary => _summary;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isSummarizing = false;
  bool get isSummarizing => _isSummarizing;

  bool _isOcrLoading = false;
  bool get isOcrLoading => _isOcrLoading;

  int _recordingSeconds = 0;
  int get recordingSeconds => _recordingSeconds;
  Timer? _recordingTimer;

  List<Map<String, dynamic>> _savedNotes = [];
  List<Map<String, dynamic>> get savedNotes => _savedNotes;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> get courses => _courses;

  String? _selectedCourseId;
  String? get selectedCourseId => _selectedCourseId;
  Map<String, dynamic>? get selectedCourse {
    if (_selectedCourseId == null) return null;
    try {
      return _courses.firstWhere(
        (c) => _courseIdOf(c) == _selectedCourseId,
      );
    } catch (_) {
      return null;
    }
  }

  String _errorMessage = '';
  @override
  String get errorMessage => _errorMessage;

  String _qaQuestion = '';
  String get qaQuestion => _qaQuestion;
  String _qaAnswer = '';
  String get qaAnswer => _qaAnswer;
  bool _isQaLoading = false;
  bool get isQaLoading => _isQaLoading;

  late Box _notesBox;

  /// Deep-casts a dynamic map (from Hive) to Map<String, dynamic>.
  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _normalizeValue(v)));
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  static Map<String, dynamic> _castMap(dynamic item) {
    if (item is Map) {
      return item.map((k, v) => MapEntry(k.toString(), _normalizeValue(v)));
    }
    return {};
  }

  /// Deep-casts a dynamic list of maps (from Hive) to List<Map<String, dynamic>>.
  static List<Map<String, dynamic>> _castList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => _castMap(e)).toList();
    }
    return [];
  }

  Future<void> init() async {
    _notesBox = await Hive.openBox('moubser_notes_box');
    final cachedCourseId = _notesBox.get('selected_course_id');
    _selectedCourseId = cachedCourseId?.toString();
    await _ttsService.init();
    await _sttService.init();
    _aiService.init();
    await _loadNotes();
    await _loadCourses();
  }

  String get formattedTime {
    final min = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _loadCourses() async {
    try {
      final data = await Supabase.instance.client.from('courses').select();
      _courses = _castList(data);
      await _notesBox.put('courses', _courses);
    } catch (_) {
      final cached = _notesBox.get('courses', defaultValue: []);
      _courses = _castList(cached);
    }
    if (_selectedCourseId != null &&
        !_courses.any((c) => _courseIdOf(c) == _selectedCourseId)) {
      _selectedCourseId = null;
    }
    notifyListeners();
  }

  void selectCourse(Map<String, dynamic>? course) {
    _selectedCourseId = _courseIdOf(course);
    unawaited(_notesBox.put('selected_course_id', _selectedCourseId));
    notifyListeners();
  }

  void selectCourseById(String? courseId) {
    _selectedCourseId = courseId;
    unawaited(_notesBox.put('selected_course_id', _selectedCourseId));
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    _transcript = '';
    _summary = '';
    _errorMessage = '';
    _qaQuestion = '';
    _qaAnswer = '';
    _isSummarizing = false;
    _isRecording = true;
    _recordingSeconds = 0;
    notifyListeners();

    HapticFeedback.mediumImpact();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingSeconds++;
      notifyListeners();
    });

    await _sttService.startListening(
      onResult: (text, isFinal) {
        _transcript = text;
        notifyListeners();
      },
    );
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    notifyListeners();

    HapticFeedback.mediumImpact();

    await _sttService.stopListening();
    notifyListeners();

    if (_transcript.isNotEmpty) {
      await _ttsService.speak(_transcript);
    } else {
      _setError('مافي نص مسجل');
    }
  }

  Future<void> readFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;

      _isOcrLoading = true;
      _errorMessage = '';
      notifyListeners();

      final extractedText = await _ocrService.extractTextFromPath(pickedFile.path);

      _transcript = extractedText;
      _isOcrLoading = false;
      notifyListeners();

      if (extractedText.isNotEmpty) {
        await _ttsService.speak(extractedText);
      } else {
        _setError('لم يتم التعرف على نص في الصورة');
      }
    } catch (e) {
      _isOcrLoading = false;
      _setError('خطأ في الكاميرا: $e');
    }
  }

  Future<void> summarizeTranscript() async {
    if (_transcript.isEmpty) {
      _setError('مافي نص للتلخيص');
      return;
    }

    _isSummarizing = true;
    _summary = '';
    _errorMessage = '';
    notifyListeners();

    try {
      _summary = await _aiService.summarizeText(_transcript);
      _isSummarizing = false;
      notifyListeners();

      if (_summary.isNotEmpty) {
        try {
          await saveToDatabase();
        } catch (_) {
          // Save error is non-critical, summary was generated successfully
          debugPrint('خطأ أثناء حفظ الملخص تلقائياً: $_');
        }
        try {
          await _ttsService.speak(_summary);
        } catch (_) {
          // TTS failure is non-critical for summary generation.
          debugPrint('خطأ أثناء نطق الملخص: $_');
        }
      } else {
        _setError('فشل إنشاء الملخص');
      }
    } catch (e) {
      _isSummarizing = false;
      debugPrint('خطأ في التلخيص: $e');
      _setError('حدث خطأ أثناء التلخيص، حاول مرة أخرى');
    }
  }

  Future<void> askQuestion(String question) async {
    if (question.isEmpty || _transcript.isEmpty) return;

    _qaQuestion = question;
    _qaAnswer = '';
    _isQaLoading = true;
    notifyListeners();

    try {
      _qaAnswer = await _aiService.answerQuestion(question, _transcript);
      _isQaLoading = false;
      notifyListeners();

      if (_qaAnswer.isNotEmpty) {
        await _ttsService.speak(_qaAnswer);
      } else {
        _setError('فشل الحصول على إجابة');
      }
    } catch (e) {
      _isQaLoading = false;
      notifyListeners();
      debugPrint('فشل إجابة السؤال: $e');
      _setError('تعذر إكمال الطلب حالياً، حاول مرة أخرى');
    }
  }

  Future<void> saveToDatabase() async {
    if (_transcript.isEmpty && _summary.isEmpty) {
      _setError('مافي نص للحفظ');
      return;
    }

    final course = selectedCourse;
    final note = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': course != null
          ? '${_courseNameOf(course)} - ${DateTime.now().toString().substring(0, 10)}'
          : 'محاضرة ${DateTime.now().toString().substring(0, 10)}',
      'transcript': _transcript.isNotEmpty ? _transcript : null,
      'summary_content': _summary.isNotEmpty ? _summary : null,
      'date': DateTime.now().toIso8601String(),
      'course_id': _courseIdOf(course),
      'course_name': _courseNameOf(course),
    };

    final notes = _castList(_notesBox.get('notes', defaultValue: []));
    notes.insert(0, note);
    await _notesBox.put('notes', notes);
    await _notesBox.flush();

    _savedNotes.insert(0, note);
    notifyListeners();

    await _ttsService.speak('تم الحفظ');

    _trySaveToSupabase(note);
  }

  Future<void> _trySaveToSupabase(Map<String, dynamic> note) async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return;

      final data = <String, Object?>{
        'summary_content': note['summary_content'],
        'transcript': note['transcript'],
        'title': note['title'],
      };
      final courseId = selectedCourse?['course_id'] ?? note['course_id'];
      if (courseId != null) {
        data['course_id'] = courseId;
      }

      await Supabase.instance.client.from('lecture_notes').insert(data);
    } catch (_) {}
  }

  Future<void> deleteNote(dynamic noteId) async {
    final noteIdKey = noteId?.toString();
    _savedNotes.removeWhere((n) => n['id']?.toString() == noteIdKey);

    final notes = _castList(_notesBox.get('notes', defaultValue: []));
    notes.removeWhere((n) => n['id']?.toString() == noteIdKey);
    await _notesBox.put('notes', notes);
    await _notesBox.flush();

    notifyListeners();

    try {
      await Supabase.instance.client
          .from('lecture_notes')
          .delete()
          .eq('id', noteId);
    } catch (_) {}
  }

  Future<void> _loadNotes() async {
    _savedNotes = _castList(_notesBox.get('notes', defaultValue: []));
    notifyListeners();

    try {
      final data = await Supabase.instance.client
          .from('lecture_notes')
          .select()
          .order('date', ascending: false)
          .limit(20);
      final remoteNotes = _castList(data);
      for (final note in remoteNotes) {
        final exists = _savedNotes.any(
          (n) => n['id']?.toString() == note['id']?.toString(),
        );
        if (!exists) {
          note['_remote'] = true;
          _savedNotes.add(note);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> readAloud(String text) async {
    await _ttsService.speak(text);
  }

  void clearAll() {
    _transcript = '';
    _summary = '';
    _isRecording = false;
    _isSummarizing = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingSeconds = 0;
    _errorMessage = '';
    _qaQuestion = '';
    _qaAnswer = '';
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
    _ttsService.speak(message);
    scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String? _courseIdOf(Map<String, dynamic>? course) {
    if (course == null) return null;
    return (course['course_id'] ?? course['id'])?.toString();
  }

  String _courseNameOf(Map<String, dynamic>? course) {
    if (course == null) return '';
    return (course['course_name'] ?? course['name'] ?? '').toString();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _sttService.dispose();
    _ttsService.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}
