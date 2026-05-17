import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'base_viewmodel.dart';
import '../../di/locator.dart';
import '../../services/emergency_contacts_service.dart';
import '../../services/gps_service.dart';
import '../../services/supabase_service.dart';
import '../../services/tts_service.dart';

class SosViewModel extends BaseViewModel {
  final GpsService _gpsService = GpsService();
  final TtsService _ttsService = TtsService();
  final SupabaseService _supabaseService = locator<SupabaseService>();
  final EmergencyContactsService _contactsService = EmergencyContactsService();

  bool _isSending = false;
  bool get isSending => _isSending;

  bool _isSent = false;
  bool get isSent => _isSent;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    await _ttsService.init();
  }

  Future<void> sendSos() async {
    _isSending = true;
    _isSent = false;
    _statusMessage = 'جاري إرسال طلب المساعدة...';
    notifyListeners();
    await _ttsService.speak(_statusMessage);

    try {
      final studentId = await _supabaseService.getCurrentStudentId();
      final userId = await _supabaseService.getCurrentUserId();
      if (studentId == null || userId == null) {
        throw Exception('CURRENT_STUDENT_NOT_FOUND');
      }

      Position? position = await _gpsService.getCurrentPosition();
      String locationStr = 'غير متوفر';
      if (position != null) {
        locationStr = '${position.latitude},${position.longitude}';
      }

      await Supabase.instance.client.from('support_requests').insert({
        'student_id': studentId,
        'status': 'Pending',
        'location': locationStr,
      });

      final emergencyUsers =
          await _contactsService.getLinkedEmergencyUsers(studentId);
      final sosText =
          'SOS: تم إرسال طلب مساعدة من الطالب رقم $studentId. الموقع: $locationStr';
      for (final target in emergencyUsers) {
        final receiverId = target['user_id'];
        if (receiverId == null) continue;
        await Supabase.instance.client.from('messages').insert({
          'sender_id': userId,
          'receiver_id': receiverId,
          'content': sosText,
          'status': 'Sent',
        });
      }

      _isSent = true;
      _statusMessage = emergencyUsers.isEmpty
          ? 'تم إرسال طلب المساعدة! لا توجد جهات طوارئ مضافة بعد'
          : 'تم إرسال طلب المساعدة وإشعار جهات الطوارئ';
      _isSending = false;
      notifyListeners();
      await _ttsService.speak(_statusMessage);
    } catch (e) {
      _statusMessage = 'صار خطأ. حاول مرة ثانية';
      _isSending = false;
      notifyListeners();
      await _ttsService.speak(_statusMessage);
    }
  }

  void reset() {
    _isSending = false;
    _isSent = false;
    _statusMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
