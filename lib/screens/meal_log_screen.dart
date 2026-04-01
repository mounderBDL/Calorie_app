import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

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
    if (mounted) setState(() { _logs = logs; _isLoading = false; });
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

  String _formatDate(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Group logs by date
  Map<String, List<MealLog>> get _groupedLogs {
    final Map<String, List<MealLog>> grouped = {};
    for (final log in _logs) {
      final key = _formatDate(log.loggedAt);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadLogs,
        child: CustomScrollView(
          slivers: [
            // ── App bar ─────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.background,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meal Log',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                      Text('Pull to refresh',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Today summary card ───────────────
            SliverToBoxAdapter(
              child: Padding(
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
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Calories',
                            style: GoogleFonts.dmSans(
                              color: Colors.white70, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                          Text('${_todayCalories.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Meals today',
                            style: GoogleFonts.dmSans(
                              color: Colors.white70, fontSize: 12)),
                          Text(
                            '${_logs.where((l) {
                              final now = DateTime.now();
                              return l.loggedAt.year == now.year &&
                                  l.loggedAt.month == now.month &&
                                  l.loggedAt.day == now.day;
                            }).length}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1),
              ),
            ),

            // ── Log list ─────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (_logs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 64,
                          color: colors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No meals logged yet',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w600,
                          color: colors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Scan a food to get started',
                        style: GoogleFonts.dmSans(
                          fontSize: 14, color: colors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entries = _groupedLogs.entries.toList();
                    final entry   = entries[index];
                    final dateKey = entry.key;
                    final dayLogs = entry.value;
                    final dayCalories = dayLogs.fold(
                        0.0, (s, l) => s + l.totalCalories);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateKey,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: colors.textSecondary,
                                    letterSpacing: 0.5)),
                                Text('${dayCalories.toStringAsFixed(0)} kcal',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: AppTheme.primary)),
                              ],
                            ),
                          ),
                          // Meal cards for this day
                          ...dayLogs.asMap().entries.map((e) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MealLogCard(log: e.value, colors: colors),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 60 * e.key),
                              duration: 300.ms,
                            ).slideX(begin: 0.05),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _groupedLogs.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MealLogCard extends StatelessWidget {
  final MealLog log;
  final AppColors colors;
  const _MealLogCard({required this.log, required this.colors});

  @override
  Widget build(BuildContext context) {
    final time = '${log.loggedAt.hour.toString().padLeft(2, '0')}:'
        '${log.loggedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
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
                  _MacroChip('P ${log.totalProtein.toStringAsFixed(0)}g',
                      const Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  _MacroChip('C ${log.totalCarbs.toStringAsFixed(0)}g',
                      AppTheme.accent),
                  const SizedBox(width: 4),
                  _MacroChip('F ${log.totalFat.toStringAsFixed(0)}g',
                      AppTheme.primary),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.totalCalories.toStringAsFixed(0)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              Text('kcal',
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: colors.textSecondary)),
              const SizedBox(height: 2),
              Text(time,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
