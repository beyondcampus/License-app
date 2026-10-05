import 'package:flutter/material.dart';

/// Raw palette extracted from the HTML design reference (`UI desigb.html`).
/// Dark values are the source of truth; light values are derived with the
/// same accent hues.
abstract final class AppColors {
  // Accents (shared across both themes).
  static const Color blue = Color(0xFF3B82F6);
  static const Color green = Color(0xFF22C55E);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFEAB308);

  // Dark theme surfaces & text.
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkNavBackground = Color(0xFF0B1329);
  static const Color darkCodeBackground = Color(0xFF090D16);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTimerText = Color(0xFFF87171);
  static const Color darkCorrectText = Color(0xFF86EFAC);
  static const Color darkIncorrectText = Color(0xFFFCA5A5);
  static const Color darkCodeText = Color(0xFFA7F3D0);
  static const Color darkFormulaText = Color(0xFF60A5FA);
  static const Color darkExplanationText = Color(0xFF93C5FD);

  // Light theme surfaces & text (derived).
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightNavBackground = Color(0xFFFFFFFF);
  static const Color lightCodeBackground = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTimerText = Color(0xFFDC2626);
  static const Color lightCorrectText = Color(0xFF15803D);
  static const Color lightIncorrectText = Color(0xFFB91C1C);
  static const Color lightCodeText = Color(0xFF047857);
  static const Color lightFormulaText = Color(0xFF2563EB);
  static const Color lightExplanationText = Color(0xFF1D4ED8);
}

/// Semantic colors resolved per-theme. Widgets read these via
/// `context.appColors` and never branch on brightness themselves.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.navBackground,
    required this.codeBackground,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.yellow,
    required this.timerText,
    required this.correctText,
    required this.incorrectText,
    required this.codeText,
    required this.formulaText,
    required this.explanationText,
  });

  final Color background;
  final Color surface;
  final Color navBackground;
  final Color codeBackground;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color success;
  final Color warning;
  final Color error;
  final Color yellow;
  final Color timerText;
  final Color correctText;
  final Color incorrectText;
  final Color codeText;
  final Color formulaText;
  final Color explanationText;

  // Tinted fills used throughout the HTML design.
  Color get correctFill => success.withValues(alpha: 0.15);
  Color get incorrectFill => error.withValues(alpha: 0.15);
  Color get timerFill => error.withValues(alpha: 0.15);
  Color get explanationFill => primary.withValues(alpha: 0.10);
  Color get streakFill => warning.withValues(alpha: 0.20);
  Color get primaryFill => primary.withValues(alpha: 0.12);

  static const AppColorsExtension dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    navBackground: AppColors.darkNavBackground,
    codeBackground: AppColors.darkCodeBackground,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    primary: AppColors.blue,
    success: AppColors.green,
    warning: AppColors.orange,
    error: AppColors.red,
    yellow: AppColors.yellow,
    timerText: AppColors.darkTimerText,
    correctText: AppColors.darkCorrectText,
    incorrectText: AppColors.darkIncorrectText,
    codeText: AppColors.darkCodeText,
    formulaText: AppColors.darkFormulaText,
    explanationText: AppColors.darkExplanationText,
  );

  static const AppColorsExtension light = AppColorsExtension(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    navBackground: AppColors.lightNavBackground,
    codeBackground: AppColors.lightCodeBackground,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    primary: AppColors.blue,
    success: AppColors.green,
    warning: AppColors.orange,
    error: AppColors.red,
    yellow: AppColors.yellow,
    timerText: AppColors.lightTimerText,
    correctText: AppColors.lightCorrectText,
    incorrectText: AppColors.lightIncorrectText,
    codeText: AppColors.lightCodeText,
    formulaText: AppColors.lightFormulaText,
    explanationText: AppColors.lightExplanationText,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? navBackground,
    Color? codeBackground,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? success,
    Color? warning,
    Color? error,
    Color? yellow,
    Color? timerText,
    Color? correctText,
    Color? incorrectText,
    Color? codeText,
    Color? formulaText,
    Color? explanationText,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      navBackground: navBackground ?? this.navBackground,
      codeBackground: codeBackground ?? this.codeBackground,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      yellow: yellow ?? this.yellow,
      timerText: timerText ?? this.timerText,
      correctText: correctText ?? this.correctText,
      incorrectText: incorrectText ?? this.incorrectText,
      codeText: codeText ?? this.codeText,
      formulaText: formulaText ?? this.formulaText,
      explanationText: explanationText ?? this.explanationText,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      timerText: Color.lerp(timerText, other.timerText, t)!,
      correctText: Color.lerp(correctText, other.correctText, t)!,
      incorrectText: Color.lerp(incorrectText, other.incorrectText, t)!,
      codeText: Color.lerp(codeText, other.codeText, t)!,
      formulaText: Color.lerp(formulaText, other.formulaText, t)!,
      explanationText: Color.lerp(explanationText, other.explanationText, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.dark;
}
