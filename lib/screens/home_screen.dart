import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

final homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<MealLog> _logs         = [];
  bool          _loading      = true;
  DateTime      _selectedDate = DateTime.now();

  late final ScrollController _dateScrollController;
  static const int    _kPastDays    = 90;
  static const int    _kFutureDays  = 7;
  static const double _kDayCellWidth = 46.0;

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
    _load();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToDate(_selectedDate));
  }

  Future<void> _load() async {
    final db     = context.read<DatabaseService>();
    final auth   = context.read<AuthService>();
    final userId = auth.currentUserId ?? '';
    setState(() => _loading = true);
    final logs = await db.getMealHistory(userId: userId);
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void refresh() => _load();

  void _scrollToDate(DateTime date) {
    if (!_dateScrollController.hasClients) return;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    final index = _kPastDays + d.difference(today).inDays;
    final pos   = _dateScrollController.position;
    final offset =
        index * _kDayCellWidth - pos.viewportDimension / 2 + _kDayCellWidth / 2;
    _dateScrollController.animateTo(
      offset.clamp(0.0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  static String _monthName(int m) => const [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ][m - 1];

  // ── Helpers ───────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool get _isSelectedToday {
    final now = DateTime.now();
    return _selectedDate.year  == now.year  &&
           _selectedDate.month == now.month &&
           _selectedDate.day   == now.day;
  }

  List<MealLog> get _selectedLogs => _logs.where((l) =>
    l.loggedAt.year  == _selectedDate.year  &&
    l.loggedAt.month == _selectedDate.month &&
    l.loggedAt.day   == _selectedDate.day).toList();

  double get _selCalories => _selectedLogs.fold(0.0, (s, l) => s + l.totalCalories);
  double get _selCarbs    => _selectedLogs.fold(0.0, (s, l) => s + l.totalCarbs);
  double get _selProtein  => _selectedLogs.fold(0.0, (s, l) => s + l.totalProtein);
  double get _selFat      => _selectedLogs.fold(0.0, (s, l) => s + l.totalFat);

  String get _sectionTitle {
    if (_isSelectedToday) return "Today's Meals";
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return "${days[_selectedDate.weekday - 1]}'s Meals";
  }

  String get _leftForLabel {
    if (_isSelectedToday) return 'left for today';
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return 'left for ${days[_selectedDate.weekday - 1]}';
  }

  static String _formatHeaderDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  static String _formatMealTime(DateTime dt) {
    final h      = dt.hour;
    final m      = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12    = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final user      = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.trim().split(' ').first ?? '';
    final prefs     = context.watch<PreferencesService>();
    final goal      = prefs.dailyCalorieGoal;
    final consumed  = _selCalories;
    final remaining = (goal - consumed).clamp(0.0, goal.toDouble());
    final progress  = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final pct       = (progress * 100).round();

    final carbGoal    = prefs.dailyCarbGoal.toDouble();
    final proteinGoal = prefs.dailyProteinGoal.toDouble();
    final fatGoal     = prefs.dailyFatGoal.toDouble();

    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final datesWithMeals = _logs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet();
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Header ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting,
                              style: GoogleFonts.dmSans(
                                fontSize: 13, color: colors.textSecondary,
                                fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(
                              firstName.isNotEmpty ? '$firstName 👋' : 'Welcome 👋',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: colors.textPrimary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.green,
                                  shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(_formatHeaderDate(now),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppTheme.green)),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 18),

                    // ── Date strip header ─────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: colors.textPrimary)),
                        if (!_isSelectedToday)
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = today);
                              _scrollToDate(today);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Today',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppTheme.primary)),
                            ),
                          ),
                      ],
                    ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

                    const SizedBox(height: 8),

                    // ── Scrollable day strip ───────────────
                    Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SingleChildScrollView(
                          controller: _dateScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: List.generate(
                              _kPastDays + _kFutureDays + 1,
                              (i) {
                                final date = today.add(
                                    Duration(days: i - _kPastDays));
                                final isToday    = date == today;
                                final isSelected =
                                    date.year  == _selectedDate.year  &&
                                    date.month == _selectedDate.month &&
                                    date.day   == _selectedDate.day;
                                final hasMeal = datesWithMeals.contains(date);
                                return SizedBox(
                                  width: _kDayCellWidth,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedDate = date),
                                    child: _DayCell(
                                      label:  weekdayLabels[date.weekday - 1],
                                      dayNum: date.day,
                                      isSelected: isSelected,
                                      isToday:    isToday,
                                      hasMeal:    hasMeal && !isSelected,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // ── Calorie summary card (MFP style) ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          // Big remaining number
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TweenAnimationBuilder<double>(
                                key: ValueKey('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}-rem'),
                                tween: Tween(begin: 0, end: remaining),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                builder: (_, val, __) => Text(
                                  val.toStringAsFixed(0),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 52, fontWeight: FontWeight.w800,
                                    color: colors.textPrimary, height: 1.0)),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('Cal',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: colors.textPrimary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_leftForLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 13, color: colors.textSecondary)),
                          const SizedBox(height: 16),
                          // Consumed row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Icon(Icons.local_fire_department_rounded,
                                  color: AppTheme.primary, size: 18),
                                const SizedBox(width: 5),
                                Text('Consumed ($pct%)',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: colors.textPrimary)),
                              ]),
                              Row(children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.green,
                                    shape: BoxShape.circle),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.white, size: 13),
                                ),
                                const SizedBox(width: 6),
                                Text('${consumed.toStringAsFixed(0)} Cal',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppTheme.green)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Green progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}-prog'),
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (_, val, __) => LinearProgressIndicator(
                                value: val,
                                minHeight: 7,
                                backgroundColor:
                                    AppTheme.green.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 500.ms)
                                .slideY(begin: 0.08),

                    const SizedBox(height: 16),

                    // ── Macro row ─────────────────────────
                    Row(
                      children: [
                        Expanded(child: _MacroCard(
                          key:      ValueKey('carbs-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                          label:    'Carbs',
                          consumed: _selCarbs,
                          goal:     carbGoal,
                          color:    AppTheme.primary,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _MacroCard(
                          key:      ValueKey('protein-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                          label:    'Protein',
                          consumed: _selProtein,
                          goal:     proteinGoal,
                          color:    AppTheme.green,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _MacroCard(
                          key:      ValueKey('fat-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                          label:    'Fat',
                          consumed: _selFat,
                          goal:     fatGoal,
                          color:    const Color(0xFF9C27B0),
                        )),
                      ],
                    ).animate().fadeIn(delay: 220.ms, duration: 500.ms),

                    const SizedBox(height: 24),

                    // ── Meals section header ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_sectionTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: colors.textPrimary)),
                        Text('${_selectedLogs.length} logged',
                          style: GoogleFonts.dmSans(
                            fontSize: 12, color: colors.textSecondary)),
                      ],
                    ).animate().fadeIn(delay: 280.ms, duration: 400.ms),

                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // ── Meals list ───────────────────────────
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5)),
                )
              else if (_selectedLogs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded,
                          size: 56,
                          color: colors.textSecondary.withValues(alpha: 0.28)),
                        const SizedBox(height: 14),
                        Text(
                          _isSelectedToday
                              ? 'No meals logged today'
                              : 'No meals on this day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: colors.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          _isSelectedToday
                              ? 'Tap + to log your first meal'
                              : 'Select another day or log a meal',
                          style: GoogleFonts.dmSans(
                            fontSize: 13, color: colors.textSecondary)),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _MealCard(
                        log:       _selectedLogs[i],
                        colors:    colors,
                        timeLabel: _formatMealTime(_selectedLogs[i].loggedAt),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 40 * i),
                        duration: 300.ms).slideY(begin: 0.05),
                      childCount: _selectedLogs.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────
class _DayCell extends StatelessWidget {
  final String label;
  final int    dayNum;
  final bool   isSelected; // highlighted with green circle
  final bool   isToday;    // today's date (unselected state)
  final bool   hasMeal;

  const _DayCell({
    required this.label,
    required this.dayNum,
    required this.isSelected,
    required this.isToday,
    required this.hasMeal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Label color: green when selected or today, grey otherwise
    final labelColor = (isSelected || isToday)
        ? AppTheme.green
        : colors.textSecondary;

    // Number color: white when selected, green when today-unselected, grey otherwise
    final numColor = isSelected
        ? Colors.white
        : isToday
            ? AppTheme.green
            : colors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: labelColor,
            fontWeight: (isSelected || isToday)
                ? FontWeight.w700 : FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.green : Colors.transparent,
            shape: BoxShape.circle,
            border: (!isSelected && isToday)
                ? Border.all(color: AppTheme.green, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text('$dayNum',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: numColor)),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: hasMeal ? AppTheme.green : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ── Macro mini-card ───────────────────────────
class _MacroCard extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color  color;

  const _MacroCard({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final progress  = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - consumed).clamp(0.0, goal);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 52, height: 52,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, val, __) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: val,
                    strokeWidth: 5,
                    backgroundColor: color.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  SizedBox(
                    width: 30,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        consumed.toStringAsFixed(0),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: colors.textPrimary)),
          const SizedBox(height: 1),
          Text('${remaining.toStringAsFixed(0)}g left',
            style: GoogleFonts.dmSans(
              fontSize: 11, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Meal card ─────────────────────────────────
class _MealCard extends StatelessWidget {
  final MealLog   log;
  final AppColors colors;
  final String    timeLabel;

  const _MealCard({
    required this.log,
    required this.colors,
    required this.timeLabel,
  });

  String get _emoji {
    final n = log.foodClassName.toLowerCase();
    if (['couscous','chourba','bourek','kofta','harira','rechta',
         'mhajeb','dolma','shorba_frik','berkoukes','mechoui','merguez']
        .any(n.contains)) { return '🇩🇿'; }
    if (['cake','baklava','cheesecake','ice_cream','pancake','waffle',
         'donut','cookie','brownie','muffin','chocolate']
        .any(n.contains)) { return '🍰'; }
    if (['salad','vegetable','spinach','broccoli'].any(n.contains)) { return '🥗'; }
    if (['pizza'].any(n.contains))                                  { return '🍕'; }
    if (['burger','hamburger','sandwich'].any(n.contains))          { return '🍔'; }
    if (['pasta','spaghetti','ramen','noodle'].any(n.contains))     { return '🍝'; }
    if (['rice','fried_rice'].any(n.contains))                      { return '🍚'; }
    if (['chicken','steak','beef','lamb','kebab'].any(n.contains))  { return '🥩'; }
    if (['salmon','fish','seafood'].any(n.contains))                { return '🐟'; }
    if (['egg','omelette'].any(n.contains))                         { return '🍳'; }
    return '🍽';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 22))),
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
                const SizedBox(height: 2),
                Text(timeLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(log.totalCalories.toStringAsFixed(0),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              Text('kcal',
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
