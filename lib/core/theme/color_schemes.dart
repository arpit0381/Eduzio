import 'package:flutter/material.dart';
import '../constants/colors.dart';

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primaryLight,
  onPrimary: AppColors.onPrimaryLight,
  primaryContainer: AppColors.primaryContainerLight,
  onPrimaryContainer: AppColors.onPrimaryContainerLight,
  secondary: AppColors.secondaryLight,
  onSecondary: AppColors.onSecondaryLight,
  secondaryContainer: AppColors.secondaryContainerLight,
  onSecondaryContainer: AppColors.onSecondaryContainerLight,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.backgroundLight,
  onSurface: AppColors.onBackgroundLight,
  surfaceContainerHighest: Color(0xFFE2E1EC),
  onSurfaceVariant: Color(0xFF45464F),
  outline: Color(0xFF757680),
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primaryDark,
  onPrimary: AppColors.onPrimaryDark,
  primaryContainer: AppColors.primaryContainerDark,
  onPrimaryContainer: AppColors.onPrimaryContainerDark,
  secondary: AppColors.secondaryDark,
  onSecondary: AppColors.onSecondaryDark,
  secondaryContainer: AppColors.secondaryContainerDark,
  onSecondaryContainer: AppColors.onSecondaryContainerDark,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.backgroundDark,
  onSurface: AppColors.onBackgroundDark,
  surfaceContainerHighest: Color(0xFF24252E),
  onSurfaceVariant: Color(0xFFC5C6D0),
  outline: Color(0xFF8F909A),
);
