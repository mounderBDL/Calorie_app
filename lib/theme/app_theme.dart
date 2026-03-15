import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Warm palette ─────────────────────────────
  static const Color primary       = Color(0xFFE8622A); // warm orange
  static const Color primaryLight  = Color(0xFFF5865A);
  static const Color primaryDark   = Color(0xFFBF4718);
  static const Color accent        = Color(0xFFF4A261); // soft amber
  static const Color accentWarm    = Color(0xFFE76F51); // terracotta

  // Light theme colors
  static const Color bgLight       = Color(0xFFFAF7F2); // warm cream
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color cardLight     = Color(0xFFFFF8F0); // warm white
  static const Color textPrimLight = Color(0xFF2D1B0E); // dark brown
  static const Color textSecLight  = Color(0xFF8B6347); // warm brown
  static const Color dividerLight  = Color(0xFFEDD5B8);

  // Dark theme colors
  static const Color bgDark        = Color(0xFF1A1108); // very dark brown
  static const Color surfaceDark   = Color(0xFF261A0D); // dark brown
  static const Color cardDark      = Color(0xFF332211); // medium dark brown
  static const Color textPrimDark  = Color(0xFFFAF0E0); // warm white
  static const Color textSecDark   = Color(0xFFCCA882); // warm tan
  static const Color dividerDark   = Color(0xFF4A3020);

  // ── Light Theme ──────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimLight,
    ),
    scaffoldBackgroundColor: bgLight,
    textTheme: _textTheme(textPrimLight, textSecLight),
    appBarTheme: AppBarTheme(
      backgroundColor: bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: textPrimLight),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: textPrimLight,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1),
    extensions: const [AppColors.light],
  );

  // ── Dark Theme ───────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimDark,
    ),
    scaffoldBackgroundColor: bgDark,
    textTheme: _textTheme(textPrimDark, textSecDark),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: textPrimDark),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: textPrimDark,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: dividerDark, thickness: 1),
    extensions: const [AppColors.dark],
  );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 48, fontWeight: FontWeight.w700, color: primary),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 36, fontWeight: FontWeight.w700, color: primary),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28, fontWeight: FontWeight.w600, color: primary),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 24, fontWeight: FontWeight.w600, color: primary),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 20, fontWeight: FontWeight.w600, color: primary),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w500, color: primary),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: primary, letterSpacing: 0.5),
  );
}

// ── Theme extension for custom colors ────────
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const AppColors({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const light = AppColors(
    background:    AppTheme.bgLight,
    card:          AppTheme.cardLight,
    textPrimary:   AppTheme.textPrimLight,
    textSecondary: AppTheme.textSecLight,
    divider:       AppTheme.dividerLight,
  );

  static const dark = AppColors(
    background:    AppTheme.bgDark,
    card:          AppTheme.cardDark,
    textPrimary:   AppTheme.textPrimDark,
    textSecondary: AppTheme.textSecDark,
    divider:       AppTheme.dividerDark,
  );

  @override
  AppColors copyWith({
    Color? background, Color? card,
    Color? textPrimary, Color? textSecondary, Color? divider,
  }) => AppColors(
    background:    background    ?? this.background,
    card:          card          ?? this.card,
    textPrimary:   textPrimary   ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    divider:       divider       ?? this.divider,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background:    Color.lerp(background,    other.background,    t)!,
      card:          Color.lerp(card,          other.card,          t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider:       Color.lerp(divider,       other.divider,       t)!,
    );
  }
}
