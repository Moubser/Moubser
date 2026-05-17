import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/locator.dart';
import '../../services/tts_service.dart';
import '../../services/groq_service.dart';
import '../../services/object_detector_service.dart';

import '../views/navigation_view.dart';
import '../views/attendance_view.dart';
import '../views/smart_reader_view.dart';
import '../views/chat_view.dart';
import '../views/sos_view.dart';
import '../views/profile_view.dart';

class VoiceAssistantDialog extends StatefulWidget {
  const VoiceAssistantDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const VoiceAssistantDialog(),
    );
  }

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog>
    with SingleTickerProviderStateMixin {
  final _tts = locator<TtsService>();
  final _groqService = GroqService();
  final _recorder = Record();
  final _objectDetector = ObjectDetectorService();
  final _imagePicker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String _statusText = 'جاهز';
  String _recognizedText = '';
  bool _isRecording = false;
  bool _actionTaken = false;
  bool _isProcessing = false;
  String? _currentFilePath;

  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initAssistant();
  }

  Future<void> _initAssistant() async {
    setState(() => _statusText = 'جاري التهيئة...');

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _statusText = 'يرجى إعطاء صلاحية المايكروفون');
      await _tts.speak('أعط صلاحية المايك من الإعدادات');
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _statusText = 'اضغط وتحدث');
    await _tts.speak('اضغط على الزر وتحدث لأفتح لك الصفحة المطلوبة');
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    _actionTaken = false;
    _hasSpoken = false;

    final hasMic = await _recorder.hasPermission();
    if (!hasMic) {
      setState(() {
        _statusText = 'المايك غير متاح';
      });
      await _tts.speak('ما في صلاحية للمايك');
      return;
    }

    final dir = Directory.systemTemp;
    _currentFilePath = '${dir.path}/assistant_${DateTime.now().millisecondsSinceEpoch}.wav';

    setState(() {
      _isRecording = true;
      _statusText = 'تحدث الآن...';
      _recognizedText = '';
    });

    _animationController.repeat(reverse: true);

    try {
      await _recorder.start(
        path: _currentFilePath!,
        encoder: AudioEncoder.wav,
        samplingRate: 16000,
        numChannels: 1,
      );
      _startSilenceDetection();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusText = 'فشل بدء التسجيل';
      });
    }
  }

  void _startSilenceDetection() {
    _amplitudeSub = _recorder.onAmplitudeChanged(Duration(milliseconds: 200)).listen((amplitude) {
      if (amplitude.current > -35.0) {
        _hasSpoken = true;
        _silenceTimer?.cancel();
        _silenceTimer = null;
      } else if (_hasSpoken && _silenceTimer == null) {
        _silenceTimer = Timer(const Duration(seconds: 2), () {
          if (_isRecording && mounted) {
            _stopRecording();
          }
        });
      }
    });

    _maxDurationTimer = Timer(const Duration(seconds: 15), () {
      if (_isRecording && mounted) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();
    _animationController.stop();
    _animationController.reset();
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusText = 'جاري التعرف على الصوت...';
    });

    try {
      await _recorder.stop();
    } catch (_) {}

    if (_currentFilePath == null || _actionTaken) {
      setState(() => _isProcessing = false);
      return;
    }

    final text = await _groqService.transcribeAudio(_currentFilePath!);

    try {
      File(_currentFilePath!).delete();
    } catch (_) {}

    _currentFilePath = null;

    if (!mounted || _actionTaken) {
      setState(() => _isProcessing = false);
      return;
    }

    setState(() {
      _recognizedText = text;
      _isProcessing = false;
    });

    if (text.isEmpty) {
      setState(() => _statusText = 'لم أتمكن من التعرف على الصوت');
      await _tts.speak('ما فهمت، حاول مرة ثانية');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _statusText = 'اضغط وتحدث');
      }
      return;
    }

    _processCommand(text);
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '');
  }

  Future<void> _processCommand(String text) async {
    if (_actionTaken) return;

    final normalized = _normalizeArabic(text.toLowerCase());

    Widget? targetView;
    String feedback = '';

    if (normalized.contains('خريطه') || normalized.contains('تنقل') || normalized.contains('طريق') || normalized.contains('مكان')) {
      targetView = const NavigationView();
      feedback = 'جاري فتح الخريطة';
    } else if (normalized.contains('حضور') || normalized.contains('بصمه') || normalized.contains('تحضير')) {
      targetView = const AttendanceView();
      feedback = 'جاري فتح الحضور';
    } else if (normalized.contains('قارئ') || normalized.contains('قراءه') || normalized.contains('محاضره') || normalized.contains('نص')) {
      targetView = const SmartReaderView();
      feedback = 'جاري فتح القارئ الذكي';
    } else if (normalized.contains('محادث') || normalized.contains('تواصل') || normalized.contains('رسال')) {
      targetView = const ChatView();
      feedback = 'جاري فتح المحادثات';
    } else if (normalized.contains('مساعده') || normalized.contains('طوارئ') || normalized.contains('انقاذ') || normalized.contains('نجده')) {
      targetView = const SosView();
      feedback = 'جاري طلب المساعدة';
    } else if (normalized.contains('ملف') || normalized.contains('شخصي') || normalized.contains('حساب')) {
      targetView = const ProfileView();
      feedback = 'جاري فتح الملف الشخصي';
    } else if (normalized.contains('امسح') || normalized.contains('مسح') || normalized.contains('كشف') || normalized.contains('محيط') || normalized.contains('اشوف') || normalized.contains('شوف')) {
      _actionTaken = true;
      setState(() => _statusText = 'جاري مسح المحيط');
      await _tts.speak('جاري مسح المحيط');
      final picked = await _imagePicker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        final result = await _objectDetector.scanImage(picked.path);
        if (result.isNotEmpty) {
          setState(() => _statusText = result);
          await _tts.speak(result);
        } else {
          setState(() => _statusText = 'ما في عوائق قدامك');
          await _tts.speak('طريقك سالك توكل على الله');
        }
      } else {
        setState(() => _statusText = 'تم إلغاء المسح');
        await _tts.speak('تم إلغاء المسح');
      }
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
      return;
    } else if (normalized.contains('اغلاق') || normalized.contains('رجوع') || normalized.contains('الغاء')) {
      _actionTaken = true;
      if (mounted) Navigator.pop(context);
      return;
    } else {
      setState(() => _statusText = 'لم أتمكن من التعرف على الأمر');
      await _tts.speak('ما فهمت الأمر، حاول مرة ثانية');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _statusText = 'اضغط وتحدث');
      }
      return;
    }

    if (targetView != null) {
      _actionTaken = true;
      setState(() => _statusText = feedback);
      await _tts.speak(feedback);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetView!));
      }
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    _amplitudeSub?.cancel();
    _animationController.dispose();
    _recorder.dispose();
    _objectDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المساعد الصوتي',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 30),
            Semantics(
              label: _isRecording ? 'اضغط للإيقاف' : 'اضغط للتحدث',
              button: true,
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _scaleAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFFD34B4B)
                              : (_isProcessing
                                  ? AppColors.grey.withOpacity(0.3)
                                  : AppColors.primary),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : (_isProcessing
                                  ? Icons.hourglass_top_rounded
                                  : Icons.mic),
                          size: 60,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            Semantics(
              liveRegion: true,
              child: Text(
                _statusText,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            if (_recognizedText.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  '"$_recognizedText"',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            Semantics(
              label: 'إلغاء',
              button: true,
              child: TextButton(
                onPressed: () {
                  _recorder.stop();
                  Navigator.pop(context);
                },
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
