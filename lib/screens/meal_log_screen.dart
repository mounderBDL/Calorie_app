import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'nutrition_screen.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});
  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  List<MealLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

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

  double get _todayCalories {
    final today = DateTime.now();
    return _logs
        .where((l) =>
            l.loggedAt.year  == today.year &&
            l.loggedAt.month == today.month &&
            l.loggedAt.day   == today.day)
        .fold(0.0, (sum, l) => sum + l.totalCalories);
  }

  int get _todayMealCount {
    final now = DateTime.now();
    return _logs.where((l) =>
        l.loggedAt.year  == now.year &&
        l.loggedAt.month == now.month &&
        l.loggedAt.day   == now.day).length;
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

            // ── Summary card with calorie ring ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accentWarm],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16, offset: const Offset(0, 6),
                  )],
                ),
                child: Row(
                  children: [
                    // Animated calorie ring
                    SizedBox(
                      width: 80, height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_todayCalories),
                            tween: Tween(
                              begin: 0.0,
                              end: (_todayCalories / 2000).clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOut,
                            builder: (_, value, __) {
                              return CircularProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                          SizedBox(
                            width: 50,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _todayCalories.toStringAsFixed(0),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18, fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    )),
                                  Text('kcal',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10, color: Colors.white70,
                                      fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s intake',
                            style: GoogleFonts.dmSans(
                              color: Colors.white70, fontSize: 12,
                              fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            '${_todayCalories.toStringAsFixed(0)} / 2000 kcal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_todayMealCount ${_todayMealCount == 1 ? 'meal' : 'meals'} today',
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.white,
                                fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
