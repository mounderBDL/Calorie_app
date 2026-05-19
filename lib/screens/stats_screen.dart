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

final statsScreenKey = GlobalKey<StatsScreenState>();

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  List<MealLog> _logs    = [];
  bool          _loading = true;
  late final ScrollController _chartCtrl;

  static const int    _monthDays  = 30;
  static const double _barW       = 26.0;
  static const double _maxBarH    = 78.0;
  static const double _labelAreaH = 18.0;
  static const double _chartH     = _maxBarH + _labelAreaH + 4;

  @override
  void initState() {
    super.initState();
    _chartCtrl = ScrollController();
    _load();
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  void refresh() => _load();

  Future<void> _load() async {
    final db   = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    setState(() => _loading = true);
    final logs = await db.getMealHistory(userId: auth.currentUserId ?? '');
    if (!mounted) return;
    setState(() { _logs = logs; _loading = false; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartCtrl.hasClients) {
        _chartCtrl.jumpTo(_chartCtrl.position.maxScrollExtent);
      }
    });
  }

  // ── Computed stats ────────────────────────────

  double get _avgDailyCalories {
    final days = _logs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet();
    if (days.isEmpty) return 0;
    return _logs.fold(0.0, (s, l) => s + l.totalCalories) / days.length;
  }

  int get _longestStreak {
    final dates = _logs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet()
        .toList()
      ..sort();
    if (dates.isEmpty) return 0;
    int longest = 1, current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  List<double> get _monthCalories {
    final now = DateTime.now();
    return List.generate(_monthDays, (i) {
      final day = now.subtract(Duration(days: _monthDays - 1 - i));
      return _logs
          .where((l) =>
              l.loggedAt.year  == day.year &&
              l.loggedAt.month == day.month &&
              l.loggedAt.day   == day.day)
          .fold(0.0, (s, l) => s + l.totalCalories);
    });
  }

  Map<String, double> get _weekAvgMacros {
    final now      = DateTime.now();
    final weekLogs = _logs
        .where((l) => now.difference(l.loggedAt).inDays < 7)
        .toList();
    if (weekLogs.isEmpty) return {'carbs': 0, 'protein': 0, 'fat': 0};
    final loggedDays = weekLogs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet()
        .length;
    final divisor = loggedDays > 0 ? loggedDays.toDouble() : 1.0;
    return {
      'carbs':   weekLogs.fold(0.0, (s, l) => s + l.totalCarbs)   / divisor,
      'protein': weekLogs.fold(0.0, (s, l) => s + l.totalProtein) / divisor,
      'fat':     weekLogs.fold(0.0, (s, l) => s + l.totalFat)     / divisor,
    };
  }

  List<MapEntry<String, int>> get _topFoods {
    final counts = <String, int>{};
    for (final log in _logs) {
      counts[log.foodDisplayName] = (counts[log.foodDisplayName] ?? 0) + 1;
    }
    return (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final prefs  = context.watch<PreferencesService>();
    final goal   = prefs.dailyCalorieGoal.toDouble();

    final monthCals  = _monthCalories;
    final weekMacros = _weekAvgMacros;
    final topFoods   = _topFoods;
    final now        = DateTime.now();

    final maxCal   = monthCals.fold(0.0, (prev, v) => v > prev ? v : prev);
    final monthMax = max(goal * 1.2, maxCal > 0 ? maxCal * 1.05 : goal);

    final goalLinePct    = (goal / monthMax).clamp(0.0, 1.0);
    final goalLineBottom = _labelAreaH + goalLinePct * _maxBarH;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5))
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Header ───────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stats',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28, fontWeight: FontWeight.w700,
                                      color: colors.textPrimary)),
                                  Text('Your progress & insights',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: colors.textSecondary)),
                                ],
                              ),
                              GestureDetector(
                                onTap: _load,
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
                          ).animate().fadeIn(duration: 400.ms),

                          const SizedBox(height: 24),

                          // ── ① Hero stats row ─────────────────
                          Row(children: [
                            Expanded(child: _StatChip(
                              label:  'Total Meals',
                              value:  '${_logs.length}',
                              icon:   Icons.restaurant_rounded,
                              color:  AppTheme.primary,
                              colors: colors,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _StatChip(
                              label: 'Daily Avg',
                              value: _avgDailyCalories > 0
                                  ? _avgDailyCalories.toStringAsFixed(0)
                                  : '—',
                              unit:  _avgDailyCalories > 0 ? 'kcal' : null,
                              icon:  Icons.local_fire_department_rounded,
                              color: AppTheme.green,
                              colors: colors,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _StatChip(
                              label: 'Best Streak',
                              value: '$_longestStreak',
                              unit:  _longestStreak == 1 ? 'day' : 'days',
                              icon:  Icons.whatshot_rounded,
                              color: const Color(0xFF9C27B0),
                              colors: colors,
                            )),
                          ]).animate().fadeIn(delay: 80.ms, duration: 400.ms),

                          const SizedBox(height: 20),

                          // ── ② Monthly calorie chart ───────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Monthly Overview',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary)),
                                        Text('Last 30 days · kcal/day',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: colors.textSecondary)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flag_rounded,
                                              size: 12,
                                              color: AppTheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${goal.toStringAsFixed(0)} kcal',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Scrollable bar chart
                                SizedBox(
                                  height: _chartH,
                                  child: SingleChildScrollView(
                                    controller: _chartCtrl,
                                    scrollDirection: Axis.horizontal,
                                    child: Stack(
                                      children: [
                                        // Bars
                                        SizedBox(
                                          width:  _monthDays * _barW,
                                          height: _chartH,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: List.generate(
                                                _monthDays, (i) {
                                              final day = now.subtract(
                                                  Duration(
                                                      days: _monthDays - 1 - i));
                                              final cal     = monthCals[i];
                                              final isToday = i == _monthDays - 1;
                                              final barH    = cal > 0
                                                  ? (cal / monthMax * _maxBarH)
                                                      .clamp(3.0, _maxBarH)
                                                  : 3.0;
                                              final Color barColor;
                                              if (cal == 0) {
                                                barColor = colors.textSecondary
                                                    .withValues(alpha: 0.12);
                                              } else if (cal <= goal) {
                                                barColor = AppTheme.green;
                                              } else {
                                                barColor = Colors.red.shade400;
                                              }

                                              return SizedBox(
                                                width: _barW,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      height: barH,
                                                      margin: EdgeInsets
                                                          .symmetric(
                                                              horizontal:
                                                                  isToday
                                                                      ? 3.0
                                                                      : 4.5),
                                                      decoration: BoxDecoration(
                                                        color: barColor,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        4)),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      isToday
                                                          ? '●'
                                                          : '${day.day}',
                                                      style:
                                                          GoogleFonts.dmSans(
                                                        fontSize: 8,
                                                        fontWeight: isToday
                                                            ? FontWeight.w900
                                                            : FontWeight.w400,
                                                        color: isToday
                                                            ? AppTheme.primary
                                                            : colors
                                                                .textSecondary
                                                                .withValues(
                                                                    alpha:
                                                                        0.6)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),

                                        // Dashed goal line
                                        Positioned(
                                          left:   0,
                                          right:  0,
                                          bottom: goalLineBottom,
                                          child: Row(
                                            children: List.generate(
                                              (_monthDays * _barW / 8)
                                                  .ceil(),
                                              (i) => Expanded(
                                                child: Container(
                                                  height: 1.5,
                                                  color: i.isEven
                                                      ? AppTheme.primary
                                                          .withValues(
                                                              alpha: 0.40)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(children: [
                                  _LegendDot(
                                      AppTheme.green, 'Under goal', colors),
                                  const SizedBox(width: 14),
                                  _LegendDot(
                                      Colors.red.shade400, 'Over goal', colors),
                                ]),
                              ],
                            ),
                          ).animate()
                              .fadeIn(delay: 140.ms, duration: 500.ms)
                              .slideY(begin: 0.06),

                          const SizedBox(height: 20),

                          // ── ③ Macro balance rings ─────────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Macro Balance',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    color: colors.textPrimary)),
                                Text("This week's daily averages vs your goals",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: colors.textSecondary)),
                                const SizedBox(height: 22),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _MacroRing(
                                      label:  'Carbs',
                                      value:  weekMacros['carbs']!,
                                      goal:   prefs.dailyCarbGoal.toDouble(),
                                      color:  AppTheme.primary,
                                      colors: colors,
                                    ),
                                    _MacroRing(
                                      label:  'Protein',
                                      value:  weekMacros['protein']!,
                                      goal:   prefs.dailyProteinGoal.toDouble(),
                                      color:  AppTheme.green,
                                      colors: colors,
                                    ),
                                    _MacroRing(
                                      label:  'Fat',
                                      value:  weekMacros['fat']!,
                                      goal:   prefs.dailyFatGoal.toDouble(),
                                      color:  const Color(0xFF9C27B0),
                                      colors: colors,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .slideY(begin: 0.06),

                          const SizedBox(height: 20),

                          // ── ④ Top foods ───────────────────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Top Foods',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    color: colors.textPrimary)),
                                Text('Most frequently logged',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: colors.textSecondary)),
                                const SizedBox(height: 16),
                                if (topFoods.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Text('No meals logged yet',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: colors.textSecondary)),
                                    ),
                                  )
                                else
                                  ...topFoods.asMap().entries.map((e) {
                                    final rank  = e.key + 1;
                                    final name  = e.value.key;
                                    final count = e.value.value;
                                    final frac  = count / topFoods.first.value;
                                    final isTop = rank == 1;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        children: [
                                          Row(children: [
                                            Container(
                                              width: 22, height: 22,
                                              decoration: BoxDecoration(
                                                color: isTop
                                                    ? AppTheme.primary
                                                    : colors.textSecondary
                                                        .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child: Text('$rank',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: isTop
                                                        ? Colors.white
                                                        : colors.textSecondary,
                                                  )),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(name,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 13,
                                                  fontWeight: isTop
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: colors.textPrimary),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            ),
                                            Text('$count×',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isTop
                                                    ? AppTheme.primary
                                                    : colors.textSecondary)),
                                          ]),
                                          const SizedBox(height: 6),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: frac),
                                            duration: Duration(
                                                milliseconds: 600 + rank * 80),
                                            curve: Curves.easeOut,
                                            builder: (_, val, __) => ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: val,
                                                minHeight: 7,
                                                backgroundColor: AppTheme
                                                    .primary
                                                    .withValues(alpha: 0.08),
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  isTop
                                                      ? AppTheme.primary
                                                      : AppTheme.primary
                                                          .withValues(
                                                              alpha: 0.45),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ).animate()
                              .fadeIn(delay: 260.ms, duration: 500.ms)
                              .slideY(begin: 0.06),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────
class _StatChip extends StatelessWidget {
  final String    label;
  final String    value;
  final String?   unit;
  final IconData  icon;
  final Color     color;
  final AppColors colors;

  const _StatChip({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: colors.textPrimary, height: 1.0)),
          if (unit != null)
            Text(unit!,
              style: GoogleFonts.dmSans(
                fontSize: 11, color: colors.textSecondary)),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 11, color: colors.textSecondary,
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Macro ring ────────────────────────────────
class _MacroRing extends StatelessWidget {
  final String    label;
  final double    value;
  final double    goal;
  final Color     color;
  final AppColors colors;

  const _MacroRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final pct      = (progress * 100).round();

    return Column(
      children: [
        SizedBox(
          width: 76, height: 76,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, val, __) => Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: val,
                  strokeWidth: 7,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text('$pct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(0)}g avg',
          style: GoogleFonts.dmSans(
            fontSize: 11, color: colors.textSecondary)),
        Text('Goal: ${goal.toStringAsFixed(0)}g',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: colors.textSecondary.withValues(alpha: 0.7))),
      ],
    );
  }
}

// ── Legend dot ────────────────────────────────
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
            color: color, borderRadius: BorderRadius.circular(2)),
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
