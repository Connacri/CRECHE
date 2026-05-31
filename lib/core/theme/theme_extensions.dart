import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color gradientStart;
  final Color gradientEnd;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const AppColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  static const light = AppColors(
    success: Color(0xFF52634A),
    warning: Color(0xFF8D4D36),
    info: Color(0xFF476368),
    gradientStart: Color(0xFF9DB093),
    gradientEnd: Color(0xFF52634A),
    cardGradientStart: Color(0xFFF9F9F7),
    cardGradientEnd: Color(0xFFEEEEEC),
  );

  static const dark = AppColors(
    success: Color(0xFFB9CCAE),
    warning: Color(0xFFFFB59C),
    info: Color(0xFFAECCD2),
    gradientStart: Color(0xFF3B4B34),
    gradientEnd: Color(0xFF101F0C),
    cardGradientStart: Color(0xFF1A1C1B),
    cardGradientEnd: Color(0xFF2F3130),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? gradientStart,
    Color? gradientEnd,
    Color? cardGradientStart,
    Color? cardGradientEnd,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      cardGradientStart:
          Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
    );
  }
}
