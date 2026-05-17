import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/sos_viewmodel.dart';

class SosView extends StatelessWidget {
  const SosView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SosViewModel()..init(),
      child: const _SosBody(),
    );
  }
}

class _SosBody extends StatelessWidget {
  const _SosBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SosViewModel>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: Text('طلب المساعدة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.red.shade700,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.emergency_rounded,
                      size: 48, color: Colors.red.shade700),
                ),
                const SizedBox(height: 24),
                Text('هل تحتاج مساعدة؟',
                    style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Text(
                  'اضغط الزر لإرسال طلب مساعدة مع موقعك الحالي\nوسيتم إشعار جهات الطوارئ المضافة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      color: AppColors.grey, fontSize: 14, height: 1.8),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: vm.isSending
                      ? null
                      : vm.sendSos,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: vm.isSent ? 120 : 140,
                    height: vm.isSent ? 120 : 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: vm.isSent
                          ? Colors.green
                          : Colors.red.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: (vm.isSent ? Colors.green : Colors.red)
                              .withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: vm.isSending
                        ? const CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 3)
                        : Icon(
                            vm.isSent
                                ? Icons.check_rounded
                                : Icons.sos_rounded,
                            color: AppColors.white,
                            size: 56,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                if (vm.statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: vm.isSent
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: vm.isSent
                              ? Colors.green.shade300
                              : Colors.orange.shade300),
                    ),
                    child: Text(vm.statusMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            color: vm.isSent
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
