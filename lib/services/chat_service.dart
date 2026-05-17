import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getConversations(
    int userId, {
    int? studentId,
  }) async {
    final sent = await _client
        .from('messages')
        .select('receiver_id')
        .eq('sender_id', userId);

    final received = await _client
        .from('messages')
        .select('sender_id')
        .eq('receiver_id', userId);

    Set<int> contactIds = {};
    for (var row in sent) {
      contactIds.add(row['receiver_id'] as int);
    }
    for (var row in received) {
      contactIds.add(row['sender_id'] as int);
    }

    if (studentId != null) {
      final emergencyRows = await _client
          .from('support_contacts')
          .select('user_id, email, phone')
          .eq('student_id', studentId);

      for (final row in emergencyRows) {
        final directUserId = row['user_id'];
        if (directUserId is int) {
          contactIds.add(directUserId);
          continue;
        }

        final email = (row['email'] ?? '').toString().trim();
        final phone = (row['phone'] ?? '').toString().trim();
        bool linked = false;
        if (email.isNotEmpty) {
          final user = await _client
              .from('users')
              .select('user_id')
              .eq('email', email)
              .maybeSingle();
          if (user != null && user['user_id'] != null) {
            contactIds.add(user['user_id'] as int);
            linked = true;
          }
        }
        if (!linked && phone.isNotEmpty) {
          final user = await _client
              .from('users')
              .select('user_id')
              .eq('phone', phone)
              .maybeSingle();
          if (user != null && user['user_id'] != null) {
            contactIds.add(user['user_id'] as int);
          }
        }
      }
    }

    contactIds.remove(userId);
    if (contactIds.isEmpty) return [];

    final users = await _client
        .from('users')
        .select()
        .inFilter('user_id', contactIds.toList());

    return List<Map<String, dynamic>>.from(users);
  }

  Future<List<Map<String, dynamic>>> getMessages(
      int userId, int otherUserId) async {
    final data = await _client
        .from('messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
        .order('sent_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'status': 'Sent',
    });
  }

  RealtimeChannel subscribeToMessages(int userId, Function(Map<String, dynamic>) onMessage) {
    return _client
        .channel('messages:receiver_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
