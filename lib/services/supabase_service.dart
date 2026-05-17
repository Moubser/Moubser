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
    required String universityNumber,
  }) async {
    final studentId = int.tryParse(universityNumber);
    if (studentId == null) {
      throw Exception('STUDENT_LINK_FAILED');
    }

    final preExistingStudent = await client
        .from('student')
        .select('student_id, user_id')
        .eq('student_id', studentId)
        .limit(1);
    if (preExistingStudent.isNotEmpty) {
      final preLinkedUserId = _asInt(preExistingStudent[0]['user_id']);
      if (preLinkedUserId != null) {
        throw Exception('STUDENT_ALREADY_LINKED');
      }
    }

    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'university_number': universityNumber,
      },
    );

    if (response.user != null) {
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      int? userId;
      try {
        final insertedUser = await client.from('users').insert({
          'firstname': firstName,
          'lastname': lastName,
          'email': email,
          'phone': phone,
          'password': '***',
        }).select('user_id').single();
        userId = _asInt(insertedUser['user_id']);
      } catch (_) {
        final existingUser = await client
            .from('users')
            .select('user_id')
            .eq('email', email)
            .limit(1);
        if (existingUser.isNotEmpty) {
          userId = _asInt(existingUser[0]['user_id']);
        }
      }

      if (userId == null) {
        throw Exception('STUDENT_LINK_FAILED');
      }

      final studentRows = await client
          .from('student')
          .select('student_id, user_id')
          .eq('student_id', studentId)
          .limit(1);

      if (studentRows.isEmpty) {
        await client.from('student').insert({
          'student_id': studentId,
          'user_id': userId,
        });
      } else {
        final existingLinkedUserId = _asInt(studentRows[0]['user_id']);
        if (existingLinkedUserId != null && existingLinkedUserId != userId) {
          throw Exception('STUDENT_ALREADY_LINKED');
        }
        await client
            .from('student')
            .update({'user_id': userId})
            .eq('student_id', studentId);
      }

      final verifyRows = await client
          .from('student')
          .select('user_id')
          .eq('student_id', studentId)
          .limit(1);
      final verifiedUserId =
          verifyRows.isEmpty ? null : _asInt(verifyRows[0]['user_id']);
      if (verifiedUserId != userId) {
        throw Exception('STUDENT_LINK_FAILED');
      }
    }

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  Future<Map<String, dynamic>?> getCurrentUserRow() async {
    final authUser = currentUser;
    final email = authUser?.email;
    if (email == null || email.isEmpty) return null;

    final row = await client
        .from('users')
        .select('user_id, firstname, lastname, email, phone')
        .eq('email', email)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<int?> getCurrentUserId() async {
    final userRow = await getCurrentUserRow();
    if (userRow == null) return null;
    return _asInt(userRow['user_id']);
  }

  Future<int?> getCurrentStudentId() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      final studentRow = await client
          .from('student')
          .select('student_id')
          .eq('user_id', userId)
          .maybeSingle();
      final studentId = studentRow == null ? null : _asInt(studentRow['student_id']);
      if (studentId != null) return studentId;
    }

    final metadataStudentId =
        _asInt(currentUser?.userMetadata?['university_number']);
    if (metadataStudentId != null) return metadataStudentId;

    return null;
  }

  /// Current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => client.auth.currentUser != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
