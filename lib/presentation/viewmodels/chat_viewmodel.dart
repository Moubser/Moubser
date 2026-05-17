import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../di/locator.dart';
import '../../services/supabase_service.dart';
import 'base_viewmodel.dart';
import '../../services/chat_service.dart';

class ChatViewModel extends BaseViewModel {
  final ChatService _chatService = ChatService();
  final SupabaseService _supabaseService = locator<SupabaseService>();

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  Map<String, dynamic>? _selectedContact;
  Map<String, dynamic>? get selectedContact => _selectedContact;

  final TextEditingController messageController = TextEditingController();

  RealtimeChannel? _channel;
  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  int? _currentStudentId;

  Future<void> init({Map<String, dynamic>? initialContact}) async {
    _currentUserId = await _supabaseService.getCurrentUserId();
    _currentStudentId = await _supabaseService.getCurrentStudentId();
    if (_currentUserId == null) {
      setError('تعذر تحديد حساب المستخدم الحالي');
      return;
    }
    await loadConversations();
    if (initialContact != null) {
      await openConversation(initialContact);
    }
  }

  Future<void> loadConversations() async {
    if (_currentUserId == null) return;
    setState(ViewState.busy);
    try {
      _conversations = await _chatService.getConversations(
        _currentUserId!,
        studentId: _currentStudentId,
      );
      setState(ViewState.idle);
    } catch (e) {
      setError('خطأ في تحميل المحادثات');
    }
  }

  Future<void> openConversation(Map<String, dynamic> contact) async {
    _selectedContact = contact;
    setState(ViewState.busy);

    try {
      _messages = await _chatService.getMessages(
        _currentUserId!,
        contact['user_id'],
      );
      setState(ViewState.idle);

      _channel?.unsubscribe();
      _channel = _chatService.subscribeToMessages(
        _currentUserId!,
        (newMessage) {
          if (newMessage['sender_id'] == contact['user_id']) {
            _messages.add(newMessage);
            notifyListeners();
          }
        },
      );
    } catch (e) {
      setError('خطأ في تحميل الرسائل');
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty || _selectedContact == null) {
      return;
    }

    String content = messageController.text.trim();
    messageController.clear();

    try {
      await _chatService.sendMessage(
        senderId: _currentUserId!,
        receiverId: _selectedContact!['user_id'],
        content: content,
      );

      _messages.add({
        'sender_id': _currentUserId,
        'receiver_id': _selectedContact!['user_id'],
        'content': content,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'Sent',
      });
      notifyListeners();
    } catch (e) {
      setError('خطأ في إرسال الرسالة');
    }
  }

  void closeConversation() {
    _selectedContact = null;
    _messages = [];
    _channel?.unsubscribe();
    _channel = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    messageController.dispose();
    super.dispose();
  }
}
