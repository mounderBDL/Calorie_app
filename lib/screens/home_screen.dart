import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/inference_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';
import 'manual_entry_screen.dart';

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

    if (result == null) return;

    if (result.confidence < 0.60) {
      _showLowConfidenceDialog();
      return;
    }

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

  void _showLowConfidenceDialog() {
    final colors = Theme.of(context).extension<AppColors>()!;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_food_rounded,
                    color: Colors.orange, size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 18),
              Text('No Food Detected',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'The image doesn\'t clearly show a recognizable food. '
                'Try a closer photo with better lighting, or use Manual Entry.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: colors.textSecondary,
                  height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ManualEntryScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Manual Entry',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Try Again',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Stack(
        children: [
          // Background orbs
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
                      Text('SmartDZMeal',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        )),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                  const SizedBox(height: 44),

                  Text(
                    'What\'s on\nyour plate?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38, fontWeight: FontWeight.w700,
                      height: 1.15, color: colors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 600.ms)
                              .slideY(begin: 0.15),

                  const SizedBox(height: 10),

                  Text(
                    'Scan, upload, or search your food to\ntrack nutrition instantly.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14, height: 1.6,
                      color: colors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 32),

                  // Take a Photo + Upload Image — side by side
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Take a Photo',
                          subtitle: 'Capture a meal',
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accentWarm],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => _pickAndAnalyze(ImageSource.camera),
                          isLight: true,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.photo_library_rounded,
                          title: 'Upload Image',
                          subtitle: 'Pick from gallery',
                          gradient: LinearGradient(
                              colors: [colors.card, colors.card]),
                          onTap: () => _pickAndAnalyze(ImageSource.gallery),
                          isLight: false,
                          hasBorder: true,
                          compact: true,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(begin: 0.2),

                  const SizedBox(height: 12),

                  // Manual Entry — full width
                  _ActionCard(
                    icon: Icons.search_rounded,
                    title: 'Manual Entry',
                    subtitle: 'Search our database and select a meal',
                    gradient: LinearGradient(colors: [
                      AppTheme.accent.withOpacity(0.15),
                      AppTheme.accent.withOpacity(0.08),
                    ]),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ManualEntryScreen())),
                    isLight: false,
                    hasBorder: true,
                    borderColor: AppTheme.accent.withOpacity(0.4),
                    iconColor: AppTheme.accent,
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
                              .slideY(begin: 0.2),

                  const Spacer(),

                  // Badge
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
                          const Text('🇩🇿',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'Supports Algerian cuisine',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            )),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 14,
                              color: colors.divider),
                          const SizedBox(width: 10),
                          Text(
                            '50+ meals',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            )),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Analyzing overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AppColors>()!.card,
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
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .extension<AppColors>()!.textPrimary,
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

// ── Action card widget ────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData   icon;
  final String     title;
  final String     subtitle;
  final Gradient   gradient;
  final VoidCallback onTap;
  final bool       isLight;
  final bool       hasBorder;
  final bool       compact;
  final Color?     borderColor;
  final Color?     iconColor;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.isLight,
    this.hasBorder  = false,
    this.compact    = false,
    this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final iconSize  = compact ? 42.0 : 50.0;
    final padding   = compact ? 14.0 : 20.0;
    final titleSize = compact ? 14.0 : 16.0;
    final subSize   = compact ? 11.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: hasBorder
              ? Border.all(
                  color: borderColor ?? colors.divider, width: 1.5)
              : null,
          boxShadow: isLight
              ? [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )]
              : null,
        ),
        padding: EdgeInsets.all(padding),
        child: compact
            // ── Compact: icon on top, text below (vertical layout)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconSize, height: iconSize,
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.white.withOpacity(0.2)
                          : (iconColor ?? AppTheme.primary).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                      color: isLight
                          ? Colors.white
                          : (iconColor ?? AppTheme.primary),
                      size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                    style: GoogleFonts.dmSans(
                      fontSize: titleSize, fontWeight: FontWeight.w700,
                      color: isLight ? Colors.white : colors.textPrimary,
                    )),
                  const SizedBox(height: 3),
                  Text(subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: subSize,
                      color: isLight
                          ? Colors.white.withOpacity(0.8)
                          : colors.textSecondary,
                    )),
                ],
              )
            // ── Full: horizontal layout
            : Row(
                children: [
                  Container(
                    width: iconSize, height: iconSize,
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.white.withOpacity(0.2)
                          : (iconColor ?? AppTheme.primary).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                      color: isLight
                          ? Colors.white
                          : (iconColor ?? AppTheme.primary),
                      size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                          style: GoogleFonts.dmSans(
                            fontSize: titleSize, fontWeight: FontWeight.w700,
                            color: isLight ? Colors.white : colors.textPrimary,
                          )),
                        const SizedBox(height: 3),
                        Text(subtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: subSize,
                            color: isLight
                                ? Colors.white.withOpacity(0.8)
                                : colors.textSecondary,
                          )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isLight
                        ? Colors.white.withOpacity(0.8)
                        : colors.textSecondary),
                ],
              ),
      ),
    );
  }
}
