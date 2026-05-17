import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class NutritionScreen extends StatelessWidget {
  final PredictionResult prediction;
  final List<Ingredient> ingredients;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const NutritionScreen({
    super.key,
    required this.prediction,
    required this.ingredients,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final db     = context.read<DatabaseService>();
    final auth   = context.read<AuthService>();

    final totalMacroG = totalProtein + totalCarbs + totalFat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Hero calorie card ───────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentWarm],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: Column(
                children: [
                  Text('Total Energy',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                  const SizedBox(height: 6),
                  // Hero tag matches the banner in IngredientsScreen
                  Hero(
                    tag: 'calorie_hero',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        totalCalories.toStringAsFixed(0),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text('kilocalories',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 16,
                    )),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MacroPill('P', totalProtein),
                      const SizedBox(width: 10),
                      _MacroPill('C', totalCarbs),
                      const SizedBox(width: 10),
                      _MacroPill('F', totalFat),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // ── Macro breakdown bars ────────────
            Text('Macro Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              )),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _MacroBar(
                    label: 'Protein',
                    grams: totalProtein,
                    total: totalMacroG,
                    color: const Color(0xFF4CAF50),
                    colors: colors,
                  ),
                  const SizedBox(height: 18),
                  _MacroBar(
                    label: 'Carbs',
                    grams: totalCarbs,
                    total: totalMacroG,
                    color: AppTheme.accent,
                    colors: colors,
                  ),
                  const SizedBox(height: 18),
                  _MacroBar(
                    label: 'Fat',
                    grams: totalFat,
                    total: totalMacroG,
                    color: AppTheme.primary,
                    colors: colors,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Per-ingredient breakdown ────────
            Text('Ingredient Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              )),
            const SizedBox(height: 14),

            ...ingredients.asMap().entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IngredientNutrRow(entry.value, colors),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 200 + 50 * entry.key),
                duration: 300.ms,
              ).slideX(begin: 0.05),
            ),

            const SizedBox(height: 28),

            // ── Save meal button ────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final userId = auth.currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please sign in to save meals.',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    return;
                  }

                  await db.logMeal(
                    MealLog(
                      foodClassName:   prediction.className,
                      foodDisplayName: prediction.displayName,
                      totalCalories:   totalCalories,
                      totalProtein:    totalProtein,
                      totalCarbs:      totalCarbs,
                      totalFat:        totalFat,
                      loggedAt:        DateTime.now(),
                    ),
                    userId: userId,
                  );

                  if (!context.mounted) return;

                  Navigator.of(context).popUntil((route) => route.isFirst);
                  mainScreenKey.currentState?.switchToMealLog();
                },
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text('Save Meal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ── Animated horizontal macro bar ────────────
class _MacroBar extends StatelessWidget {
  final String label;
  final double grams;
  final double total;
  final Color color;
  final AppColors colors;

  const _MacroBar({
    required this.label,
    required this.grams,
    required this.total,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (grams / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                )),
            ]),
            Text(
              '${grams.toStringAsFixed(1)}g  ·  ${(pct * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              )),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: pct),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, value, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: colors.divider,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Macro pill ────────────────────────────────
class _MacroPill extends StatelessWidget {
  final String label;
  final double value;
  const _MacroPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text('$label  ${value.toStringAsFixed(1)}g',
        style: GoogleFonts.dmSans(
          fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Per-ingredient nutrition row ──────────────
class _IngredientNutrRow extends StatelessWidget {
  final Ingredient ing;
  final AppColors colors;
  const _IngredientNutrRow(this.ing, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(ing.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: colors.textPrimary)),
              ),
              Text('${ing.grams.toStringAsFixed(0)}g',
                style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _NutrChip('${ing.scaledCalories.toStringAsFixed(0)} kcal',
                  const Color(0xFFFF7043)),
              _NutrChip('P ${ing.scaledProtein.toStringAsFixed(1)}g',
                  const Color(0xFF4CAF50)),
              _NutrChip('C ${ing.scaledCarbs.toStringAsFixed(1)}g',
                  AppTheme.accent),
              _NutrChip('F ${ing.scaledFat.toStringAsFixed(1)}g',
                  AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrChip extends StatelessWidget {
  final String label;
  final Color color;
  const _NutrChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
