import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Soft Minimal palette ──────────────────────
  static const Color primary       = Color(0xFFE8956D); // soft peach-salmon
  static const Color primaryLight  = Color(0xFFF2B49A);
  static const Color primaryDark   = Color(0xFFCC7050);
  static const Color accent        = Color(0xFFF0A882); // soft amber
  static const Color accentWarm    = Color(0xFFD4785A); // muted terracotta
  static const Color green         = Color(0xFF4CAF50); // progress green
  static const Color greenDark     = Color(0xFF388E3C); // deep green

  // Light theme colors
  static const Color bgLight       = Color(0xFFFAF8F5); // warm off-white
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color cardLight     = Color(0xFFFFFFFF); // pure white cards
  static const Color textPrimLight = Color(0xFF2D1B0E); // dark brown
  static const Color textSecLight  = Color(0xFF9E7D6A); // warm brown
  static const Color dividerLight  = Color(0xFFEDE8E3); // soft divider

  // Dark theme colors
  static const Color bgDark        = Color(0xFF1A1108);
  static const Color surfaceDark   = Color(0xFF261A0D);
  static const Color cardDark      = Color(0xFF332211);
  static const Color textPrimDark  = Color(0xFFFAF0E0);
  static const Color textSecDark   = Color(0xFFCCA882);
  static const Color dividerDark   = Color(0xFF4A3020);

  // ── Reusable soft shadow ──────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Light Theme ───────────────────────────────
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
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimLight,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1),
    extensions: const [AppColors.light],
  );

  // ── Dark Theme ────────────────────────────────
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
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimDark,
        fontSize: 20,
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
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dividerDark),
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
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 48, fontWeight: FontWeight.w800, color: primary),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 36, fontWeight: FontWeight.w700, color: primary),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 28, fontWeight: FontWeight.w700, color: primary),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 24, fontWeight: FontWeight.w700, color: primary),
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

// ── Theme extension for custom colors ─────────
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
