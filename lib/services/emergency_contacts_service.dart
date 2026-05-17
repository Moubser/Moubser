import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactsService {
  SupabaseClient get _client => Supabase.instance.client;

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  Future<int?> _getStudentIdForUser(int userId) async {
    final studentRow = await _client
        .from('student')
        .select('student_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (studentRow == null) return null;
    return _asInt(studentRow['student_id']);
  }

  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    final user = await _client
        .from('users')
        .select('user_id, firstname, lastname, email, phone')
        .eq('email', email)
        .maybeSingle();
    if (user == null) return null;
    return Map<String, dynamic>.from(user);
  }

  Future<Map<String, dynamic>?> _getUserByPhone(String phone) async {
    final user = await _client
        .from('users')
        .select('user_id, firstname, lastname, email, phone')
        .eq('phone', phone)
        .maybeSingle();
    if (user == null) return null;
    return Map<String, dynamic>.from(user);
  }

  Future<Map<String, dynamic>?> findRegisteredUser(String query) async {
    final value = query.trim();
    if (value.isEmpty) return null;

    Map<String, dynamic>? user;
    final isEmail = value.contains('@');
    final isNumber = RegExp(r'^\d+$').hasMatch(value);

    if (isEmail) {
      user = await _getUserByEmail(value);
    } else if (isNumber) {
      final studentId = int.tryParse(value);
      if (studentId != null) {
        final student = await _client
            .from('student')
            .select('student_id, user_id')
            .eq('student_id', studentId)
            .maybeSingle();
        if (student != null) {
          final userId = _asInt(student['user_id']);
          if (userId != null) {
            final userRow = await _client
                .from('users')
                .select('user_id, firstname, lastname, email, phone')
                .eq('user_id', userId)
                .maybeSingle();
            if (userRow != null) {
              user = Map<String, dynamic>.from(userRow);
              user['student_id'] = _asInt(student['student_id']);
            }
          }
        }
      }
      user ??= await _getUserByPhone(value);
    } else {
      user = await _getUserByPhone(value);
    }

    if (user == null) return null;

    final userId = _asInt(user['user_id']);
    if (userId != null && user['student_id'] == null) {
      user['student_id'] = await _getStudentIdForUser(userId);
    }
    return user;
  }

  Future<List<Map<String, dynamic>>> getContactsByStudentId(int studentId) async {
    final rows = await _client
        .from('support_contacts')
        .select('contact_id, student_id, user_id, name, relation, phone, email')
        .eq('student_id', studentId)
        .order('contact_id');

    final contacts = List<Map<String, dynamic>>.from(rows);
    final result = <Map<String, dynamic>>[];

    for (final contact in contacts) {
      Map<String, dynamic>? linkedUser;
      final linkedUserIdFromRow = _asInt(contact['user_id']);
      final email = (contact['email'] ?? '').toString().trim();
      final phone = (contact['phone'] ?? '').toString().trim();

      if (linkedUserIdFromRow != null) {
        final userById = await _client
            .from('users')
            .select('user_id, firstname, lastname, email, phone')
            .eq('user_id', linkedUserIdFromRow)
            .maybeSingle();
        if (userById != null) {
          linkedUser = Map<String, dynamic>.from(userById);
        }
      }

      if (linkedUser == null && email.isNotEmpty) {
        linkedUser = await _getUserByEmail(email);
      }
      linkedUser ??= phone.isNotEmpty ? await _getUserByPhone(phone) : null;

      if (linkedUser != null) {
        final linkedUserId = _asInt(linkedUser['user_id']);
        contact['linked_user_id'] = linkedUserId;
        contact['linked_firstname'] = linkedUser['firstname'];
        contact['linked_lastname'] = linkedUser['lastname'];
        contact['linked_email'] = linkedUser['email'];
        contact['linked_phone'] = linkedUser['phone'];
        if (linkedUserId != null) {
          contact['linked_student_id'] = await _getStudentIdForUser(linkedUserId);
        }
      }

      result.add(contact);
    }

    return result;
  }

  Future<bool> addEmergencyContact({
    required int studentId,
    required Map<String, dynamic> user,
  }) async {
    final linkedUserId = _asInt(user['user_id']);
    final email = (user['email'] ?? '').toString().trim();
    final phone = (user['phone'] ?? '').toString().trim();
    final firstName = (user['firstname'] ?? '').toString().trim();
    final lastName = (user['lastname'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();

    if (linkedUserId == null) {
      throw Exception('CONTACT_USER_REQUIRED');
    }

    if (email.isEmpty && phone.isEmpty) {
      throw Exception('CONTACT_INFO_MISSING');
    }

    Map<String, dynamic>? existing = await _client
        .from('support_contacts')
        .select('contact_id')
        .eq('student_id', studentId)
        .eq('user_id', linkedUserId)
        .maybeSingle();

    if (existing == null && email.isNotEmpty) {
      existing = await _client
          .from('support_contacts')
          .select('contact_id')
          .eq('student_id', studentId)
          .eq('email', email)
          .maybeSingle();
    }
    if (existing == null && phone.isNotEmpty) {
      existing = await _client
          .from('support_contacts')
          .select('contact_id')
          .eq('student_id', studentId)
          .eq('phone', phone)
          .maybeSingle();
    }

    if (existing != null) {
      return false;
    }

    await _client.from('support_contacts').insert({
      'student_id': studentId,
      'user_id': linkedUserId,
      'name': fullName.isNotEmpty ? fullName : 'Emergency Contact',
      'relation': 'جهة طوارئ',
      'phone': phone,
      'email': email,
    });

    return true;
  }

  Future<void> removeContact(int contactId) async {
    await _client.from('support_contacts').delete().eq('contact_id', contactId);
  }

  Future<List<Map<String, dynamic>>> getLinkedEmergencyUsers(int studentId) async {
    final contacts = await getContactsByStudentId(studentId);
    final users = <Map<String, dynamic>>[];
    final seen = <int>{};

    for (final c in contacts) {
      final userId = _asInt(c['linked_user_id']);
      if (userId == null || seen.contains(userId)) continue;
      seen.add(userId);
      users.add({
        'user_id': userId,
        'firstname': c['linked_firstname'],
        'lastname': c['linked_lastname'],
        'email': c['linked_email'],
        'phone': c['linked_phone'],
        'student_id': c['linked_student_id'],
      });
    }

    return users;
  }
}
