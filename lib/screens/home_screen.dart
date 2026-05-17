import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _picker      = ImagePicker();
  bool _isAnalyzing  = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    return '🌙';
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_food_rounded,
                    color: Colors.orange, size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 18),
              Text('No Food Detected',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'The image doesn\'t clearly show a recognizable food. '
                'Try a closer photo with better lighting, or use Manual Entry.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: colors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ManualEntryScreen()));
                    },
                    child: Text('Manual Entry',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
    final colors    = Theme.of(context).extension<AppColors>()!;
    final user      = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.trim().split(' ').first ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Background orb — top right
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Top bar ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇩🇿',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text('50+ meals',
                              style: GoogleFonts.dmSans(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // ── Greeting ─────────────────────────
                  Text('$_greeting $_greetingEmoji',
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 6),

                  Text(
                    firstName.isNotEmpty
                        ? 'What\'s on your\nplate, $firstName?'
                        : 'What\'s on\nyour plate?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      height: 1.15, color: colors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(begin: 0.15),

                  const SizedBox(height: 28),

                  // ── Hero scan card ────────────────────
                  _HeroScanCard(
                    onTap: () => _pickAndAnalyze(ImageSource.camera),
                    pulse: _pulse,
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms)
                              .slideY(begin: 0.12),

                  const SizedBox(height: 14),

                  // ── Secondary actions ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryCard(
                          icon: Icons.photo_library_rounded,
                          label: 'Upload Image',
                          onTap: () => _pickAndAnalyze(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryCard(
                          icon: Icons.search_rounded,
                          label: 'Manual Entry',
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ManualEntryScreen())),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms)
                              .slideY(begin: 0.1),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // ── Analyzing overlay ─────────────────────
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<AppColors>()!.card,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.softShadow,
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

// ── Hero scan card ────────────────────────────
class _HeroScanCard extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController pulse;

  const _HeroScanCard({required this.onTap, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.accentWarm],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.heroShadow,
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30, right: -20,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -40, left: -10,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withValues(alpha: 0.12 + 0.06 * pulse.value),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.35 + 0.15 * pulse.value),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Tap to Scan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                  const SizedBox(height: 5),
                  Text('Point your camera at a meal',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Secondary action card ─────────────────────
class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              )),
          ],
        ),
      ),
    );
  }
}
