import 'package:flutter/material.dart';
import '../../di/locator.dart';
import '../../services/emergency_contacts_service.dart';
import '../../services/supabase_service.dart';
import 'base_viewmodel.dart';

class EmergencyContactsViewModel extends BaseViewModel {
  final SupabaseService _supabaseService = locator<SupabaseService>();
  final EmergencyContactsService _contactsService = EmergencyContactsService();

  final TextEditingController searchController = TextEditingController();

  int? _currentStudentId;
  String? _accountNotice;
  String? get accountNotice => _accountNotice;
  bool get hasStudentContext => _currentStudentId != null;

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> get contacts => _contacts;

  Map<String, dynamic>? _searchResult;
  Map<String, dynamic>? get searchResult => _searchResult;

  bool _searching = false;
  bool get searching => _searching;

  bool _adding = false;
  bool get adding => _adding;

  Future<void> init() async {
    setState(ViewState.busy);
    try {
      _currentStudentId = await _supabaseService.getCurrentStudentId();
      if (_currentStudentId != null) {
        await loadContacts();
      } else {
        _accountNotice =
            'تعذر تحديد الطالب الحالي الآن. يمكنك البحث، لكن الإضافة تحتاج إعادة تسجيل الدخول.';
      }
      setState(ViewState.idle);
    } catch (_) {
      _accountNotice = 'تعذر تحميل جهات الطوارئ حالياً';
      setState(ViewState.idle);
    }
  }

  Future<void> loadContacts() async {
    if (_currentStudentId == null) return;
    _contacts = await _contactsService.getContactsByStudentId(_currentStudentId!);
    notifyListeners();
  }

  Future<void> search() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      _searchResult = null;
      notifyListeners();
      return;
    }

    _searching = true;
    notifyListeners();

    try {
      _searchResult = await _contactsService.findRegisteredUser(query);
      if (_searchResult == null) {
        setError('لا يوجد مستخدم مطابق لهذا البحث');
      } else {
        setState(ViewState.idle);
      }
    } catch (_) {
      setError('خطأ أثناء البحث');
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  Future<void> addFoundContact() async {
    if (_searchResult == null) return;
    if (_currentStudentId == null) {
      setError('لا يمكن الإضافة قبل تحديد حساب الطالب الحالي');
      return;
    }
    _adding = true;
    notifyListeners();

    try {
      final added = await _contactsService.addEmergencyContact(
        studentId: _currentStudentId!,
        user: _searchResult!,
      );
      if (!added) {
        setError('هذه الجهة مضافة مسبقًا');
      } else {
        searchController.clear();
        _searchResult = null;
        await loadContacts();
        setState(ViewState.idle);
      }
    } catch (_) {
      setError('تعذر إضافة جهة الطوارئ');
    } finally {
      _adding = false;
      notifyListeners();
    }
  }

  Future<void> removeContact(int contactId) async {
    try {
      await _contactsService.removeContact(contactId);
      await loadContacts();
    } catch (_) {
      setError('تعذر حذف جهة الطوارئ');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
