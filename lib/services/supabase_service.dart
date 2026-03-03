import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  /// Sign in with email & password
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email, password, and user metadata
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );

    if (response.user != null) {
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await client.from('users').insert({
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phone': phone,
        'password': '***',
      });
    }

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => client.auth.currentUser != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
