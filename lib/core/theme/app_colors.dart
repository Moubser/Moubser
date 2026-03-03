import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0A3D2E);
  static const Color primary = Color(0xFF0D5E4B);
  static const Color primaryLight = Color(0xFF1A7A5E);
  static const Color accent = Color(0xFF5EBAA0);
  static const Color mintLight = Color(0xFFB8E6D8);
  static const Color mintBg = Color(0xFFE8F5F0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F9F7);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
  static const Color black = Color(0xFF1A1A1A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF082E22), Color(0xFF0D5E4B), Color(0xFF1A7A5E)],
  );
}
