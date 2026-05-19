import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'nutrition_screen.dart';

final mealLogScreenKey = GlobalKey<MealLogScreenState>();

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});
  @override
  State<MealLogScreen> createState() => MealLogScreenState();
}

class MealLogScreenState extends State<MealLogScreen> {
  List<MealLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void refresh() => _loadLogs();

  Future<void> _loadLogs() async {
    final db     = context.read<DatabaseService>();
    final auth   = context.read<AuthService>();
    final userId = auth.currentUserId ?? '';

    setState(() => _isLoading = true);
    final logs = await db.getMealHistory(userId: userId);
    if (mounted) {
      setState(() { _logs = logs; _isLoading = false; });
    }
  }

  // Last 7 days calories (index 0 = 6 days ago, index 6 = today)
  List<double> get _weekCalories {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _logs
          .where((l) =>
              l.loggedAt.year  == day.year &&
              l.loggedAt.month == day.month &&
              l.loggedAt.day   == day.day)
          .fold(0.0, (s, l) => s + l.totalCalories);
    });
  }

  String _formatDate(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(date).inDays;
    if (diff == 0) { return 'Today'; }
    if (diff == 1) { return 'Yesterday'; }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, List<MealLog>> get _groupedLogs {
    final Map<String, List<MealLog>> grouped = {};
    for (final log in _logs) {
      final key = _formatDate(log.loggedAt);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  Future<void> _deleteLog(MealLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete meal?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${log.foodDisplayName}" from your log?',
          style: GoogleFonts.dmSans(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.dmSans())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
              style: GoogleFonts.dmSans(
                color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final db   = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    await db.deleteMealLog(
      id:       log.id!,
      loggedAt: log.loggedAt.toIso8601String(),
      userId:   auth.currentUserId ?? '',
    );
    if (mounted) {
      setState(() => _logs.removeWhere((l) => l.id == log.id));
    }
  }

  Future<void> _editLog(MealLog log) async {
    final db   = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMealSheet(
        log: log,
        onSave: (updated) async {
          await db.updateMealLog(
            id:          log.id!,
            oldLoggedAt: log.loggedAt.toIso8601String(),
            userId:      auth.currentUserId ?? '',
            updatedLog:  updated,
          );
          if (mounted) _loadLogs();
        },
      ),
    );
  }

  Widget _buildTrendCard(AppColors colors) {
    final goal     = context.watch<PreferencesService>().dailyCalorieGoal.toDouble();
    final weekCals = _weekCalories;
    final now      = DateTime.now();

    final weekMax = weekCals.fold(0.0, (prev, v) => v > prev ? v : prev);
    final maxVal  = max(goal * 1.2, weekMax * 1.05);

    const maxBarH = 68.0;
    const chartH  = 82.0;

    final dayLabels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return 'MTWTFSS'[day.weekday - 1];
    });

    Color barColor(double cal) {
      if (cal == 0)    return colors.textSecondary.withValues(alpha: 0.12);
      if (cal <= goal) return AppTheme.green;
      return Colors.red.shade400;
    }

    final goalLineBottom = (goal / maxVal).clamp(0.0, 1.0) * maxBarH;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Day Trend',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
                  Text('kcal per day',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: colors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 12, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('${goal.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Bars + goal line ─────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: chartH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final cal     = weekCals[i];
                    final isToday = i == 6;
                    final barH    = cal > 0
                        ? (cal / maxVal * maxBarH).clamp(3.0, maxBarH)
                        : 3.0;
                    final color   = barColor(cal);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (cal >= 50)
                            Text(
                              cal >= 1000
                                  ? '${(cal / 1000).toStringAsFixed(1)}k'
                                  : cal.toStringAsFixed(0),
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: isToday
                                    ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? color : colors.textSecondary),
                            ),
                          if (cal >= 50) const SizedBox(height: 2),
                          Container(
                            height: barH,
                            margin: EdgeInsets.symmetric(
                                horizontal: isToday ? 2.5 : 4.0),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // ── Dashed goal line ─────────────────
              Positioned(
                left: 0, right: 0,
                bottom: goalLineBottom,
                child: Row(
                  children: List.generate(36, (i) => Expanded(
                    child: Container(
                      height: 1.5,
                      color: i.isEven
                          ? AppTheme.primary.withValues(alpha: 0.40)
                          : Colors.transparent,
                    ),
                  )),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Day labels ───────────────────────────
          Row(
            children: List.generate(7, (i) {
              final isToday = i == 6;
              return Expanded(
                child: Text(
                  isToday ? 'Now' : dayLabels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: isToday ? 9 : 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? AppTheme.primary : colors.textSecondary),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // ── Legend ───────────────────────────────
          Row(children: [
            _LegendDot(AppTheme.green,      'Under goal', colors),
            const SizedBox(width: 16),
            _LegendDot(Colors.red.shade400, 'Over goal',  colors),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Fixed compact header ────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meal Log',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                      Text('Your food history',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, color: colors.textSecondary)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _loadLogs,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Icon(Icons.refresh_rounded,
                          size: 18, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // ── 7-day trend card ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: _buildTrendCard(colors),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            // ── Log list ─────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _loadLogs,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : _logs.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 280,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded,
                                          size: 64,
                                          color: colors.textSecondary
                                              .withValues(alpha: 0.35)),
                                      const SizedBox(height: 16),
                                      Text('No meals logged yet',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textSecondary)),
                                      const SizedBox(height: 8),
                                      Text('Scan a food to get started',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: colors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            itemCount: _groupedLogs.length,
                            itemBuilder: (context, index) {
                              final entries = _groupedLogs.entries.toList();
                              final entry   = entries[index];
                              final dateKey = entry.key;
                              final dayLogs = entry.value;
                              final dayCalories = dayLogs.fold(
                                  0.0, (s, l) => s + l.totalCalories);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(dateKey,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textSecondary,
                                              letterSpacing: 0.5)),
                                          Text(
                                            '${dayCalories.toStringAsFixed(0)} kcal',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primary)),
                                        ],
                                      ),
                                    ),
                                    ...dayLogs.asMap().entries.map((e) =>
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _MealLogCard(
                                          log: e.value,
                                          colors: colors,
                                          onDelete: () => _deleteLog(e.value),
                                          onEdit: () => _editLog(e.value),
                                        ),
                                      ).animate().fadeIn(
                                        delay: Duration(
                                            milliseconds: 40 * e.key),
                                        duration: 300.ms,
                                      ).slideX(begin: 0.04),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal log card with left accent strip ──────
class _MealLogCard extends StatelessWidget {
  final MealLog log;
  final AppColors colors;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _MealLogCard({
    required this.log,
    required this.colors,
    required this.onDelete,
    required this.onEdit,
  });

  // Accent color based on time of day
  Color get _accentColor {
    final h = log.loggedAt.hour;
    if (h < 10) { return const Color(0xFFFFA726); } // breakfast - amber
    if (h < 15) { return AppTheme.primary; }         // lunch - peach
    if (h < 19) { return const Color(0xFF42A5F5); }  // afternoon - blue
    return const Color(0xFF7E57C2);                   // dinner - purple
  }

  @override
  Widget build(BuildContext context) {
    final time = '${log.loggedAt.hour.toString().padLeft(2, '0')}:'
        '${log.loggedAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _openNutrition(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent strip
                Container(width: 4, color: _accentColor),

                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.restaurant_rounded,
                              color: _accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.foodDisplayName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: colors.textPrimary)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _MacroChip(
                                    'P ${log.totalProtein.toStringAsFixed(0)}g',
                                    const Color(0xFF4CAF50)),
                                const SizedBox(width: 4),
                                _MacroChip(
                                    'C ${log.totalCarbs.toStringAsFixed(0)}g',
                                    AppTheme.accent),
                                const SizedBox(width: 4),
                                _MacroChip(
                                    'F ${log.totalFat.toStringAsFixed(0)}g',
                                    AppTheme.primary),
                              ]),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(log.totalCalories.toStringAsFixed(0),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: colors.textPrimary)),
                            Text('kcal',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, color: colors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(time,
                              style: GoogleFonts.dmSans(
                                fontSize: 11, color: colors.textSecondary)),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'delete') onDelete();
                                if (v == 'edit')   onEdit();
                              },
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.more_vert_rounded,
                                  size: 18, color: colors.textSecondary),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    const Icon(Icons.edit_rounded,
                                        size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 10),
                                    Text('Edit',
                                      style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    const Icon(Icons.delete_rounded,
                                        size: 16, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Text('Delete',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNutrition(BuildContext context) async {
    final db          = context.read<DatabaseService>();
    final ingredients = await db.getIngredientsForFood(log.foodClassName);
    if (!context.mounted) { return; }

    final prediction = PredictionResult(
      className:      log.foodClassName,
      displayName:    log.foodDisplayName,
      confidence:     1.0,
      topPredictions: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionScreen(
          prediction:    prediction,
          ingredients:   ingredients,
          totalCalories: log.totalCalories,
          totalProtein:  log.totalProtein,
          totalCarbs:    log.totalCarbs,
          totalFat:      log.totalFat,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color     color;
  final String    label;
  final AppColors colors;
  const _LegendDot(this.color, this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11, color: colors.textSecondary,
            fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Edit meal bottom sheet ─────────────────────
class _EditMealSheet extends StatefulWidget {
  final MealLog log;
  final Future<void> Function(MealLog) onSave;
  const _EditMealSheet({required this.log, required this.onSave});

  @override
  State<_EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<_EditMealSheet> {
  late final TextEditingController _calCtrl;
  late final TextEditingController _protCtrl;
  late final TextEditingController _carbCtrl;
  late final TextEditingController _fatCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calCtrl  = TextEditingController(
        text: widget.log.totalCalories.toStringAsFixed(0));
    _protCtrl = TextEditingController(
        text: widget.log.totalProtein.toStringAsFixed(1));
    _carbCtrl = TextEditingController(
        text: widget.log.totalCarbs.toStringAsFixed(1));
    _fatCtrl  = TextEditingController(
        text: widget.log.totalFat.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final updated = MealLog(
      id:              widget.log.id,
      foodClassName:   widget.log.foodClassName,
      foodDisplayName: widget.log.foodDisplayName,
      totalCalories:   double.tryParse(_calCtrl.text)  ?? widget.log.totalCalories,
      totalProtein:    double.tryParse(_protCtrl.text) ?? widget.log.totalProtein,
      totalCarbs:      double.tryParse(_carbCtrl.text) ?? widget.log.totalCarbs,
      totalFat:        double.tryParse(_fatCtrl.text)  ?? widget.log.totalFat,
      loggedAt:        widget.log.loggedAt,
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Edit Meal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(widget.log.foodDisplayName,
            style: GoogleFonts.dmSans(
              fontSize: 13, color: colors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _MacroField('Calories (kcal)', _calCtrl, colors)),
            const SizedBox(width: 12),
            Expanded(child: _MacroField('Protein (g)', _protCtrl, colors)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MacroField('Carbs (g)', _carbCtrl, colors)),
            const SizedBox(width: 12),
            Expanded(child: _MacroField('Fat (g)', _fatCtrl, colors)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final AppColors colors;
  const _MacroField(this.label, this.ctrl, this.colors);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.dmSans(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 12, color: colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}
