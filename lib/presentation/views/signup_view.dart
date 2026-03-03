import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/base_viewmodel.dart';
import 'login_view.dart';
import 'home_view.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _SignUpBody(),
    );
  }
}

class _SignUpBody extends StatelessWidget {
  const _SignUpBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.35,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.chevron_right,
                            color: AppColors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo_dark.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'إنشاء حساب',
                        style: GoogleFonts.cairo(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: vm.fullNameController,
                        hint: 'الأسم الكامل',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: vm.emailController,
                        hint: 'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: vm.phoneController,
                        hint: 'رقم الهاتف',
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: vm.passwordController,
                        hint: 'كلمة المرور',
                        obscure: vm.obscurePassword,
                        textDirection: TextDirection.ltr,
                        suffixIcon: IconButton(
                          icon: Icon(
                            vm.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.white.withOpacity(0.7),
                          ),
                          onPressed: vm.togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm.state == ViewState.error &&
                          vm.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vm.errorMessage!,
                                  style: GoogleFonts.cairo(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryDark,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: vm.state == ViewState.busy
                                    ? null
                                    : () async {
                                        final success = await vm.signUp();
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'تم إنشاء الحساب بنجاح!',
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor:
                                                  AppColors.primary,
                                            ),
                                          );
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const HomeView(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: vm.state == ViewState.busy
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'تسجيل حساب',
                                        style: GoogleFonts.cairo(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'إذا لديك حساب قم ',
                            style: GoogleFonts.cairo(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginView(),
                                ),
                              );
                            },
                            child: Text(
                              'بتسجيل الدخول',
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    TextDirection textDirection = TextDirection.rtl,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textDirection: textDirection,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(color: AppColors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(
          color: AppColors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppColors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
