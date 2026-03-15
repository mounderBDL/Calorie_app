import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'ingredients_screen.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final PredictionResult prediction;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.prediction,
  });

  Color _confidenceColor(double conf) {
    if (conf >= 0.80) return const Color(0xFF4CAF50);
    if (conf >= 0.55) return AppTheme.accent;
    return const Color(0xFFE53935);
  }

  String _confidenceLabel(double conf) {
    if (conf >= 0.80) return 'High confidence';
    if (conf >= 0.55) return 'Moderate confidence';
    return 'Low confidence';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final db     = context.read<DatabaseService>();
    final conf   = prediction.confidence;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: colors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile, fit: BoxFit.cover),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Food name overlay
                  Positioned(
                    bottom: 20, left: 22, right: 22,
                    child: Text(
                      prediction.displayName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 8),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Confidence indicator ────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Confidence',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                letterSpacing: 0.5,
                              )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _confidenceColor(conf).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _confidenceLabel(conf),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _confidenceColor(conf),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearPercentIndicator(
                          lineHeight: 10,
                          percent: conf.clamp(0.0, 1.0),
                          backgroundColor: colors.divider,
                          progressColor: _confidenceColor(conf),
                          barRadius: const Radius.circular(10),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 800,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(conf * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _confidenceColor(conf),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
                              .slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // ── Top-3 predictions ───────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Other possibilities',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                            letterSpacing: 0.5,
                          )),
                        const SizedBox(height: 14),
                        ...prediction.topPredictions.skip(1).map((p) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(p.displayName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                    )),
                                ),
                                Text(
                                  '${(p.confidence * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // ── CTA buttons ─────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ingredients = await db
                            .getIngredientsForFood(prediction.className);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IngredientsScreen(
                              prediction: prediction,
                              ingredients: ingredients,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                      label: const Text('View Ingredients & Nutrition'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.camera_alt_rounded,
                          size: 20, color: AppTheme.primary),
                      label: Text('Scan Another Food',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        )),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
