import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../viewmodels/base_viewmodel.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceViewModel()..init(),
      child: const _AttendanceBody(),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceViewModel>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: Text('تسجيل الحضور',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Text('اختر المادة الدراسية',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              if (vm.state == ViewState.busy && vm.courses.isEmpty)
                const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
              else if (vm.courses.isEmpty)
                _buildEmptyCourses()
              else
                ...vm.courses.map((c) => _buildCourseCard(c, vm)),
              if (vm.selectedCourse != null) ...[
                const SizedBox(height: 20),
                _buildSelectedInfo(vm),
                const SizedBox(height: 20),
                _buildRegisterButton(vm),
              ],
              if (vm.statusMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildStatusCard(vm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.how_to_reg_rounded,
              color: AppColors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('الحضور الذكي',
                  style: GoogleFonts.cairo(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('تحقق GPS + بصمة الإصبع',
                  style:
                      GoogleFonts.cairo(color: AppColors.mintLight, fontSize: 13)),
            ])),
      ]),
    );
  }

  Widget _buildEmptyCourses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.school_rounded,
              size: 64, color: AppColors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('لا توجد مواد مسجلة',
              style: GoogleFonts.cairo(color: AppColors.grey, fontSize: 15)),
        ]),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, AttendanceViewModel vm) {
    bool isSelected = vm.selectedCourse?['course_id'] == course['course_id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => vm.selectCourse(course),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.mintBg : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.mintBg,
                  width: isSelected ? 2 : 1.5),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.mintBg,
                    shape: BoxShape.circle),
                child: Icon(Icons.book_rounded,
                    color: isSelected ? AppColors.white : AppColors.primary,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(course['course_name'] ?? 'مادة',
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark))),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedInfo(AttendanceViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                'المادة المختارة: ${vm.selectedCourse!['course_name']}',
                style: GoogleFonts.cairo(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildRegisterButton(AttendanceViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed:
            vm.isProcessing ? null : () => vm.registerAttendance(),
        icon: vm.isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white))
            : const Icon(Icons.fingerprint_rounded, size: 28),
        label: Text(vm.isProcessing ? 'جاري التسجيل...' : 'تسجيل الحضور',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildStatusCard(AttendanceViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vm.isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: vm.isSuccess
                ? Colors.green.shade300
                : Colors.orange.shade300),
      ),
      child: Row(children: [
        Icon(
            vm.isSuccess
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: vm.isSuccess ? Colors.green : Colors.orange,
            size: 28),
        const SizedBox(width: 12),
        Expanded(
            child: Text(vm.statusMessage,
                style: GoogleFonts.cairo(
                    color: vm.isSuccess
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
