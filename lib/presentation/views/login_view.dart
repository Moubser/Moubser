import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/base_viewmodel.dart';
import 'home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody();

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
                height: size.height * 0.42,
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
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/images/logo_dark.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'مرحبا بك',
                        style: GoogleFonts.cairo(
                          color: AppColors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'قم بتسجيل الدخول',
                        style: GoogleFonts.cairo(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 16,
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
                      TextField(
                        controller: vm.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'البريد الإلكتروني',
                          hintStyle: GoogleFonts.cairo(
                            color: AppColors.white.withOpacity(0.7),
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: vm.passwordController,
                        obscureText: vm.obscurePassword,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          hintStyle: GoogleFonts.cairo(
                            color: AppColors.white.withOpacity(0.7),
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
                          prefixIcon: IconButton(
                            icon: Icon(
                              vm.obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.white.withOpacity(0.7),
                            ),
                            onPressed: vm.togglePasswordVisibility,
                          ),
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
                      const SizedBox(height: 30),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mintBg,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final success = await vm.signIn();
                            if (success && context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeView(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: vm.state == ViewState.busy
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  Icons.mic,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          TextButton(
                            onPressed: () async {
                              final success = await vm.signIn();
                              if (success && context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeView(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: Text(
                              'تسجيل الدخول',
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
}
