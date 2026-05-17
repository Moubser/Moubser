import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../../services/gps_service.dart';
import '../../services/tts_service.dart';

class AttendanceViewModel extends BaseViewModel {
  final GpsService _gpsService = GpsService();
  final TtsService _ttsService = TtsService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> get courses => _courses;

  Map<String, dynamic>? _selectedCourse;
  Map<String, dynamic>? get selectedCourse => _selectedCourse;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> init() async {
    await _ttsService.init();
    await loadCourses();
  }

  Future<void> loadCourses() async {
    setState(ViewState.busy);
    try {
      final data =
          await Supabase.instance.client.from('courses').select('*, classrooms(*)');
      _courses = List<Map<String, dynamic>>.from(data);
      setState(ViewState.idle);
    } catch (e) {
      setError('خطأ في تحميل المواد الدراسية');
    }
  }

  void selectCourse(Map<String, dynamic> course) {
    _selectedCourse = course;
    notifyListeners();
  }

  Future<void> registerAttendance() async {
    if (_selectedCourse == null) {
      _statusMessage = 'اختر المادة أولاً';
      await _ttsService.speak(_statusMessage);
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _isSuccess = false;
    _statusMessage = 'جاري التحقق من الموقع...';
    notifyListeners();
    await _ttsService.speak(_statusMessage);

    try {
      // جلب student_id من المستخدم المسجل دخوله
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        _statusMessage = 'سجل دخولك أولاً';
        _isProcessing = false;
        notifyListeners();
        await _ttsService.speak(_statusMessage);
        return;
      }

      // البحث عن user_id من جدول users عبر الإيميل
      final userRows = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('email', authUser.email ?? '')
          .limit(1);

      int? studentId;
      if (userRows.isNotEmpty) {
        final userId = userRows[0]['user_id'];
        final studentRows = await Supabase.instance.client
            .from('student')
            .select('student_id')
            .eq('user_id', userId)
            .limit(1);
        if (studentRows.isNotEmpty) {
          studentId = studentRows[0]['student_id'];
        }
      }

      if (studentId == null) {
        _statusMessage = 'الطالب مو موجود';
        _isProcessing = false;
        notifyListeners();
        await _ttsService.speak(_statusMessage);
        return;
      }

      final position = await _gpsService.getCurrentPosition();
      if (position == null) {
        _statusMessage = 'ماقدرت أوصل للموقع. شغّل GPS';
        _isProcessing = false;
        notifyListeners();
        await _ttsService.speak(_statusMessage);
        return;
      }

      // التحقق من إحداثيات القاعة الدراسية المرتبطة بالمادة
      final classroom = _selectedCourse!['classrooms'];
      if (classroom != null &&
          classroom['latitude'] != null &&
          classroom['longitude'] != null) {
        bool inRange = _gpsService.isWithinGeofence(
          userLat: position.latitude,
          userLng: position.longitude,
          targetLat: (classroom['latitude'] as num).toDouble(),
          targetLng: (classroom['longitude'] as num).toDouble(),
          radiusMeters:
              (classroom['geofence_radius'] as num?)?.toDouble() ?? 50.0,
        );

        if (!inRange) {
          _statusMessage = 'أنت برا نطاق القاعة، ما تقدر تسجل';
          _isProcessing = false;
          notifyListeners();
          await _ttsService.speak(_statusMessage);
          return;
        }
      }

      _statusMessage = 'جاري التحقق من الهوية...';
      notifyListeners();
      await _ttsService.speak(_statusMessage);

      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics || isDeviceSupported) {
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'تأكيد الهوية لتسجيل الحضور',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (!authenticated) {
          _statusMessage = 'فشل التحقق';
          _isProcessing = false;
          notifyListeners();
          await _ttsService.speak(_statusMessage);
          return;
        }
      }

      _statusMessage = 'جاري تسجيل الحضور...';
      notifyListeners();

      await Supabase.instance.client.from('attendance_records').insert({
        'course_id': _selectedCourse!['course_id'],
        'student_id': studentId,
        'status': 'Present',
        'device_id': 'mobile_app',
      });

      _isSuccess = true;
      _statusMessage = 'تم تسجيل الحضور!';
      _isProcessing = false;
      notifyListeners();
      await _ttsService.speak(_statusMessage);
    } catch (e) {
      _statusMessage = 'خطأ: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      await _ttsService.speak('صار خطأ أثناء تسجيل الحضور');
    }
  }

  void reset() {
    _selectedCourse = null;
    _statusMessage = '';
    _isSuccess = false;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
