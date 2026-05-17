import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/base_viewmodel.dart';
import '../viewmodels/emergency_contacts_viewmodel.dart';
import 'chat_view.dart';
import '../widgets/voice_assistant_dialog.dart';

class EmergencyContactsView extends StatelessWidget {
  const EmergencyContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyContactsViewModel()..init(),
      child: const _EmergencyContactsBody(),
    );
  }
}

class _EmergencyContactsBody extends StatelessWidget {
  const _EmergencyContactsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EmergencyContactsViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: Text(
            'جهات الطوارئ',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => VoiceAssistantDialog.show(context),
          child: const Icon(Icons.mic, color: AppColors.white),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchCard(vm),
                const SizedBox(height: 12),
                if (vm.accountNotice != null) _buildNotice(vm.accountNotice!),
                if (vm.accountNotice != null) const SizedBox(height: 12),
                if (vm.state == ViewState.error && vm.errorMessage != null)
                  _buildError(vm.errorMessage!),
                if (vm.searchResult != null) ...[
                  const SizedBox(height: 12),
                  _buildFoundUser(context, vm),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الجهات المضافة',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.contacts.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد جهات طوارئ مضافة',
                            style: GoogleFonts.cairo(color: AppColors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: vm.contacts.length,
                          itemBuilder: (_, i) {
                            final c = vm.contacts[i];
                            return _buildContactTile(context, vm, c);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(EmergencyContactsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ابحث برقم جامعي أو بريد أو هاتف',
            style: GoogleFonts.cairo(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              TextField(
                controller: vm.searchController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'student id / email / phone',
                  hintStyle: GoogleFonts.cairo(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.searching ? null : vm.search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: vm.searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text('بحث', style: GoogleFonts.cairo()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          color: Colors.orange.shade900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(color: Colors.red.shade700),
      ),
    );
  }

  Widget _buildFoundUser(BuildContext context, EmergencyContactsViewModel vm) {
    final u = vm.searchResult!;
    final fullName = '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName.isEmpty ? 'مستخدم مسجل' : fullName,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text('البريد: ${u['email'] ?? 'غير متوفر'}',
              style: GoogleFonts.cairo(fontSize: 13)),
          Text('الهاتف: ${u['phone'] ?? 'غير متوفر'}',
              style: GoogleFonts.cairo(fontSize: 13)),
          Text('الرقم الجامعي: ${u['student_id'] ?? 'غير متوفر'}',
              style: GoogleFonts.cairo(fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: vm.adding ? null : vm.addFoundContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              icon: vm.adding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text('إضافة كجهة طوارئ', style: GoogleFonts.cairo()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    EmergencyContactsViewModel vm,
    Map<String, dynamic> c,
  ) {
    final fullName = (c['name'] ?? '').toString();
    final linkedUserId = c['linked_user_id'];
    final canChat = linkedUserId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fullName.isEmpty ? 'جهة طوارئ' : fullName,
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => vm.removeContact((c['contact_id'] as num).toInt()),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
            ],
          ),
          Text('البريد: ${c['email'] ?? 'غير متوفر'}',
              style: GoogleFonts.cairo(fontSize: 13)),
          Text('الهاتف: ${c['phone'] ?? 'غير متوفر'}',
              style: GoogleFonts.cairo(fontSize: 13)),
          if (c['linked_student_id'] != null)
            Text('الرقم الجامعي: ${c['linked_student_id']}',
                style: GoogleFonts.cairo(fontSize: 13)),
          const SizedBox(height: 8),
          if (canChat)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatView(
                        initialContact: {
                          'user_id': linkedUserId,
                          'firstname': c['linked_firstname'],
                          'lastname': c['linked_lastname'],
                          'email': c['linked_email'],
                          'phone': c['linked_phone'],
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text('محادثة', style: GoogleFonts.cairo()),
              ),
            ),
        ],
      ),
    );
  }
}
