import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatView extends StatelessWidget {
  final Map<String, dynamic>? initialContact;
  const ChatView({super.key, this.initialContact});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel()..init(initialContact: initialContact),
      child: const _ChatBody(),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: Text(
            vm.selectedContact != null
                ? '${vm.selectedContact!['firstname'] ?? ''} ${vm.selectedContact!['lastname'] ?? ''}'
                : 'المحادثات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          leading: vm.selectedContact != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => vm.closeConversation(),
                )
              : null,
        ),
        body: vm.selectedContact != null
            ? _buildMessageView(context, vm)
            : _buildConversationList(vm),
      ),
    );
  }

  Widget _buildConversationList(ChatViewModel vm) {
    if (vm.conversations.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppColors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('لا توجد محادثات بعد',
              style: GoogleFonts.cairo(color: AppColors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text('ابدأ محادثة مع جهات الطوارئ المضافة',
              style: GoogleFonts.cairo(
                  color: AppColors.grey.withOpacity(0.7), fontSize: 13)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.conversations.length,
      itemBuilder: (_, i) {
        final contact = vm.conversations[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => vm.openConversation(contact),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mintBg, width: 1.5),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: AppColors.mintBg,
                    radius: 24,
                    child: Text(
                      (contact['firstname'] ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.cairo(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${contact['firstname'] ?? ''} ${contact['lastname'] ?? ''}',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.grey),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageView(BuildContext context, ChatViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: vm.messages.isEmpty
              ? Center(
                  child: Text('لا توجد رسائل بعد',
                      style: GoogleFonts.cairo(color: AppColors.grey)),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.messages.length,
                      itemBuilder: (_, i) {
                        final msg = vm.messages[i];
                        bool isMine = msg['sender_id'] == vm.currentUserId;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.7),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft:
                                    Radius.circular(isMine ? 18 : 4),
                                bottomRight:
                                    Radius.circular(isMine ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: GoogleFonts.cairo(
                                color: isMine
                                    ? AppColors.white
                                    : AppColors.primaryDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: vm.messageController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: GoogleFonts.cairo(color: AppColors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.offWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                style: GoogleFonts.cairo(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                onPressed: () => vm.sendMessage(),
                icon: const Icon(Icons.send_rounded, color: AppColors.white),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
