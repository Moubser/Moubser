import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../di/locator.dart';
import '../../services/supabase_service.dart';
import 'welcome_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = locator<SupabaseService>();
    final user = supabase.currentUser;
    String userName = 'مستخدم';
    if (user != null &&
        user.userMetadata != null &&
        user.userMetadata!['full_name'] != null) {
      final String fullName = user.userMetadata!['full_name'];
      userName = fullName.split(' ').first;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Stack(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo_dark.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'مرحباً بك،',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.mintLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            onTap: () async {
                              await supabase.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const WelcomeView()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Icon(
                              Icons.logout,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الخدمات الجامعية',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'مبصر.. لتجربة جامعية أسهل',
                                style: GoogleFonts.cairo(
                                  color: AppColors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildServiceCard(
                            title: 'القارئ الذكي',
                            icon: Icons.document_scanner_rounded,
                            onTap: () {},
                          ),
                          _buildServiceCard(
                            title: 'الخريطة',
                            icon: Icons.map_rounded,
                            onTap: () {},
                          ),
                          _buildServiceCard(
                            title: 'الحضور',
                            icon: Icons.how_to_reg_rounded,
                            onTap: () {},
                          ),
                          _buildServiceCard(
                            title: 'الإشعارات',
                            icon: Icons.notifications_active_rounded,
                            onTap: () {},
                          ),
                          _buildServiceCard(
                            title: 'المكتبة الرقمية',
                            icon: Icons.menu_book_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.person_outline_rounded, false),
                  _buildNavItem(Icons.location_on_outlined, false),
                  Transform.translate(
                    offset: const Offset(0, -15),
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {},
                          child: const Icon(
                            Icons.mic,
                            color: AppColors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildNavItem(Icons.chat_bubble_outline_rounded, false),
                  _buildNavItem(Icons.home_rounded, true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.mintBg,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? AppColors.mintBg : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: active ? AppColors.primaryDark : AppColors.grey,
        size: 28,
      ),
    );
  }
}
