import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors (Deep Indigo / Sapphire)
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color onPrimaryLight = Colors.white;
  static const Color primaryContainerLight = Color(0xFFEEF2F6);
  static const Color onPrimaryContainerLight = Color(0xFF1E293B);

  static const Color primaryDark = Color(0xFF7C8CFF);
  static const Color onPrimaryDark = Color(0xFF0F172A);
  static const Color primaryContainerDark = Color(0xFF1E293B);
  static const Color onPrimaryContainerDark = Color(0xFFE2E8F0);

  // Secondary Colors (Teal / Accent)
  static const Color secondaryLight = Color(0xFF06B6D4);
  static const Color onSecondaryLight = Colors.white;
  static const Color secondaryContainerLight = Color(0xFFECFDF5);
  static const Color onSecondaryContainerLight = Color(0xFF064E3B);

  static const Color secondaryDark = Color(0xFF5EEAD4);
  static const Color onSecondaryDark = Color(0xFF0F172A);
  static const Color secondaryContainerDark = Color(0xFF115E59);
  static const Color onSecondaryContainerDark = Color(0xFFCCFBF1);

  // Neutral Colors (Slate / Charcoal)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color onBackgroundLight = Color(0xFF111827);
  static const Color surfaceLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF111827);

  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color onBackgroundDark = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF151B2E);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);

  // Error Colors
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // Status Colors (Custom Alert/Status colors)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // UI Redesign Pastel Colors
  static const Color pastelPurple = Color(0xFFE0E7FF);
  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelGreen = Color(0xFFDCFCE7);
  static const Color pastelOrange = Color(0xFFFFEDD5);
  static const Color pastelRed = Color(0xFFFFE4E6);
  static const Color pastelYellow = Color(0xFFFEF3C7);
  
  static const Color pastelPurpleDark = Color(0xFF312E81);
  static const Color pastelBlueDark = Color(0xFF0C4A6E);
  static const Color pastelGreenDark = Color(0xFF14532D);
  static const Color pastelOrangeDark = Color(0xFF7C2D12);
  static const Color pastelRedDark = Color(0xFF881337);
  static const Color pastelYellowDark = Color(0xFF78350F);

  static const Color pillBlack = Color(0xFF111827);
  static const Color pillWhite = Colors.white;

  // Background Gradients
  static const LinearGradient pastelBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDFBF7), // Warm cream
      Color(0xFFF4F7FF), // Soft blue tint
      Color(0xFFFFF0F5), // Soft pink/peach tint
    ],
  );
}
