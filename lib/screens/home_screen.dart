import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/inference_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;

    setState(() => _isAnalyzing = true);

    final inference = context.read<InferenceService>();
    final result    = await inference.predict(File(picked.path));

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (result != null) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a1, a2) => ResultScreen(
          imageFile: File(picked.path),
          prediction: result,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background decoration ─────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primary.withOpacity(0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withOpacity(0.12),
                  AppTheme.accent.withOpacity(0.0),
                ]),
              ),
            ),
          ),

          // ── Main content ──────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('SmartDZ Meal',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                  const SizedBox(height: 52),

                  // Hero text
                  Text(
                    'What\'s on\nyour plate?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: colors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 600.ms)
                              .slideY(begin: 0.15),

                  const SizedBox(height: 12),

                  Text(
                    'Snap or upload a food photo to instantly\nidentify it and explore its nutrition.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      height: 1.6,
                      color: colors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 52),

                  // Camera card
                  _ActionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take a Photo',
                    subtitle: 'Use your camera to capture a meal',
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentWarm],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _pickAndAnalyze(ImageSource.camera),
                    isLight: true,
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  // Gallery card
                  _ActionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    subtitle: 'Pick an existing photo to analyze',
                    gradient: LinearGradient(
                      colors: [
                        colors.card,
                        colors.card,
                      ],
                    ),
                    onTap: () => _pickAndAnalyze(ImageSource.gallery),
                    isLight: false,
                    hasBorder: true,
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
                              .slideY(begin: 0.2),

                  const Spacer(),

                  // Supported cuisines pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: colors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇩🇿', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'Supports Algerian cuisine',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 14,
                              color: colors.divider),
                          const SizedBox(width: 10),
                          Text(
                            '33 foods',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Loading overlay ───────────────────
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 3),
                      const SizedBox(height: 18),
                      Text('Analyzing your food...',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Action Card widget ────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isLight;
  final bool hasBorder;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.isLight,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: hasBorder
              ? Border.all(color: colors.divider, width: 1.5)
              : null,
          boxShadow: isLight
              ? [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )]
              : null,
        ),
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                color: isLight ? Colors.white : AppTheme.primary,
                size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isLight ? Colors.white : colors.textPrimary,
                    )),
                  const SizedBox(height: 3),
                  Text(subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: isLight
                          ? Colors.white.withOpacity(0.8)
                          : colors.textSecondary,
                    )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isLight
                  ? Colors.white.withOpacity(0.8)
                  : colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
