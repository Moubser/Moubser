import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../../di/locator.dart';
import '../../services/supabase_service.dart';

class AuthViewModel extends BaseViewModel {
  final SupabaseService _supabaseService = locator<SupabaseService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> signIn() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setError('يرجى تعبئة جميع الحقول');
      return false;
    }

    setState(ViewState.busy);
    try {
      await _supabaseService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      setState(ViewState.idle);
      return true;
    } on AuthException catch (e) {
      debugPrint('AuthException during signIn: ${e.message}');
      setError(_mapAuthError(e.message));
      return false;
    } catch (e) {
      debugPrint('Exception during signIn: $e');
      setError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      return false;
    }
  }

  Future<bool> signUp() async {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setError('يرجى تعبئة جميع الحقول');
      return false;
    }

    if (passwordController.text.length < 6) {
      setError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return false;
    }

    setState(ViewState.busy);
    try {
      await _supabaseService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      setState(ViewState.idle);
      return true;
    } on AuthException catch (e) {
      debugPrint('AuthException during signUp: ${e.message}');
      setError(_mapAuthError(e.message));
      return false;
    } catch (e) {
      debugPrint('Exception during signUp: $e');
      setError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      return false;
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (message.contains('Email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    if (message.contains('User already registered')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    }
    return message;
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
