import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Spacing scale (base unit 4) extracted from the HTML design.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(md);
}

/// Corner radii from the HTML design.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double flashcard = 20;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get flashcardAll => BorderRadius.circular(flashcard);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// Elevation: the design is flat with 1px borders; only flashcards float.
abstract final class AppElevation {
  static const double none = 0;
  static List<BoxShadow> flashcardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      offset: const Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
  ];
}

/// Text styles matching the HTML type scale. Colors are applied by the theme.
abstract final class AppTypography {
  static const String monoFontFamily = 'monospace';

  static const TextStyle scoreDisplay =
      TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2);
  static const TextStyle flashcardQuestion =
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3);
  static const TextStyle appBarTitle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle sectionTitle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle cardTitle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle questionText =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);
  static const TextStyle body =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMedium =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle meta =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle metaBold =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
  static const TextStyle caption =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
  static const TextStyle navLabel =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
  static const TextStyle code = TextStyle(
      fontSize: 12, fontFamily: monoFontFamily, height: 1.5);
  static const TextStyle formula = TextStyle(
      fontSize: 16, fontFamily: monoFontFamily, height: 1.4);
}

/// Builds the Material 3 themes from the extracted design tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColorsExtension.light, Brightness.light);
  static ThemeData dark() => _build(AppColorsExtension.dark, Brightness.dark);

  static ThemeData _build(AppColorsExtension c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: Colors.white,
      secondary: c.success,
      onSecondary: Colors.white,
      tertiary: c.warning,
      onTertiary: Colors.white,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.background,
      surfaceContainerLow: c.surface,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      shadow: Colors.black,
      scrim: Colors.black54,
    );

    final textTheme = TextTheme(
      displaySmall: AppTypography.scoreDisplay.copyWith(color: c.textPrimary),
      headlineSmall:
          AppTypography.flashcardQuestion.copyWith(color: c.textPrimary),
      titleLarge: AppTypography.appBarTitle.copyWith(color: c.textPrimary),
      titleMedium: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
      titleSmall: AppTypography.bodyMedium.copyWith(color: c.textPrimary),
      bodyLarge: AppTypography.questionText.copyWith(color: c.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: c.textPrimary),
      bodySmall: AppTypography.meta.copyWith(color: c.textSecondary),
      labelLarge: AppTypography.bodyMedium.copyWith(color: c.textPrimary),
      labelMedium: AppTypography.metaBold.copyWith(color: c.textPrimary),
      labelSmall: AppTypography.caption.copyWith(color: c.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.appBarTitle.copyWith(color: c.textPrimary),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xxlAll,
          side: BorderSide(color: c.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: AppTypography.bodyMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surface,
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: AppTypography.bodyMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.bodyMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: AppTypography.body.copyWith(color: c.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.xlAll,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.xlAll,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.xlAll,
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xxlAll,
          side: BorderSide(color: c.border),
        ),
        titleTextStyle: AppTypography.appBarTitle.copyWith(color: c.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: AppTypography.body.copyWith(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: c.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
