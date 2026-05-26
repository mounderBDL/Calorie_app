import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/inference_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'manual_entry_screen.dart';
import 'meal_log_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

export 'meal_log_screen.dart' show mealLogScreenKey;
export 'stats_screen.dart'    show statsScreenKey;

final mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int  _currentIndex  = 0;
  bool _fabOpen       = false; // logical: controls icon + toggle
  bool _fabVisible    = false; // animation: controls backdrop + options
  bool _isAnalyzing   = false;
  late final AnimationController _fabAnim;
  final _picker = ImagePicker();

  // IndexedStack screens: [Home, MealLog, Stats, Settings]
  late final List<Widget> _screens = [
    HomeScreen(key: homeScreenKey),
    MealLogScreen(key: mealLogScreenKey),
    StatsScreen(key: statsScreenKey),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<DatabaseService>().syncFromFirestore(userId: userId);
      context.read<PreferencesService>().syncFromCloud(userId);
    }
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  // Called from NutritionScreen after logging a meal
  void switchToMealLog() {
    _closeFab();
    setState(() => _currentIndex = 1);
    homeScreenKey.currentState?.refresh();
    mealLogScreenKey.currentState?.refresh();
    statsScreenKey.currentState?.refresh();
  }

  void _openFab() {
    HapticFeedback.mediumImpact();
    setState(() { _fabOpen = true; _fabVisible = true; });
    _fabAnim.forward();
  }

  void _closeFab() {
    setState(() => _fabOpen = false); // icon flips to + immediately
    _fabAnim.reverse().then((_) {
      if (mounted) setState(() => _fabVisible = false);
    });
  }

  void _toggleFab() => _fabOpen ? _closeFab() : _openFab();

  // navIndex: 0=Home 1=Log 2=FAB(center) 3=Stats 4=Profile
  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      _toggleFab();
      return;
    }
    if (_fabOpen) _closeFab();
    final screenIndex = navIndex > 2 ? navIndex - 1 : navIndex;
    setState(() => _currentIndex = screenIndex);
    if (screenIndex == 0) homeScreenKey.currentState?.refresh();
  }

  // ── Camera / image analysis ───────────────────
  Future<void> _pickAndAnalyze(ImageSource source) async {
    _closeFab();
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    final picked = await _picker.pickImage(
      source: source, imageQuality: 90, maxWidth: 1080);
    if (picked == null || !mounted) return;

    setState(() => _isAnalyzing = true);
    final result = await context.read<InferenceService>().predict(
        File(picked.path));
    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (result == null) return;

    if (result.confidence < 0.60) {
      _showLowConfidenceDialog();
      return;
    }

    await Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a1, a2) => ResultScreen(
        imageFile: File(picked.path), prediction: result),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
    homeScreenKey.currentState?.refresh();
    statsScreenKey.currentState?.refresh();
  }

  Future<void> _openManualEntry() async {
    _closeFab();
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
    homeScreenKey.currentState?.refresh();
    statsScreenKey.currentState?.refresh();
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
                  color: Colors.orange.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_food_rounded,
                    color: Colors.orange, size: 36),
              ),
              const SizedBox(height: 18),
              Text('No Food Detected',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                "The image doesn't clearly show a recognizable food. "
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
                      _openManualEntry();
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
    final colors       = Theme.of(context).extension<AppColors>()!;
    final bottomInsets = MediaQuery.of(context).padding.bottom;
    final navHighlight = _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex;

    return Scaffold(
      body: Stack(
        children: [

          // ── Screens ───────────────────────────
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // ── Backdrop ──────────────────────────
          if (_fabVisible)
            AnimatedBuilder(
              animation: _fabAnim,
              builder: (_, __) => GestureDetector(
                onTap: _closeFab,
                child: Container(
                  color: Colors.black.withValues(
                      alpha: _fabAnim.value * 0.45),
                ),
              ),
            ),

          // ── FAB options ───────────────────────
          if (_fabVisible)
            Positioned(
              right: 24,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FabOption(
                    label:    'Take Photo',
                    icon:     Icons.camera_alt_rounded,
                    color:    AppTheme.primary,
                    anim:     _fabAnim,
                    interval: const Interval(0.0, 0.80, curve: Curves.easeOut),
                    colors:   colors,
                    onTap:    () => _pickAndAnalyze(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
                  _FabOption(
                    label:    'Upload Image',
                    icon:     Icons.photo_library_rounded,
                    color:    AppTheme.green,
                    anim:     _fabAnim,
                    interval: const Interval(0.1, 0.90, curve: Curves.easeOut),
                    colors:   colors,
                    onTap:    () => _pickAndAnalyze(ImageSource.gallery),
                  ),
                  const SizedBox(height: 12),
                  _FabOption(
                    label:    'Manual Entry',
                    icon:     Icons.search_rounded,
                    color:    const Color(0xFF9C27B0),
                    anim:     _fabAnim,
                    interval: const Interval(0.2, 1.00, curve: Curves.easeOut),
                    colors:   colors,
                    onTap:    _openManualEntry,
                  ),
                ],
              ),
            ),

          // ── Analyzing overlay ─────────────────
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 28),
                  decoration: BoxDecoration(
                    color: colors.card,
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
                          color: colors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(colors, bottomInsets, navHighlight),
    );
  }

  Widget _buildNavBar(AppColors colors, double bottomInsets, int navHighlight) {
    return Container(
      color: colors.background,
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInsets + 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined,          Icons.home_rounded,
                'Home',    navHighlight),
            _navItem(1, Icons.receipt_long_outlined,   Icons.receipt_long_rounded,
                'Log',     navHighlight),
            // ── Center gradient FAB ──────────────
            GestureDetector(
              onTap: () => _onNavTap(2),
              child: AnimatedBuilder(
                animation: _fabAnim,
                builder: (_, __) => Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentWarm],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0)
                            .animate(CurvedAnimation(
                                parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      _fabOpen ? Icons.close_rounded : Icons.add_rounded,
                      key: ValueKey(_fabOpen),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            _navItem(3, Icons.bar_chart_outlined,     Icons.bar_chart_rounded,
                'Stats',   navHighlight),
            _navItem(4, Icons.person_outline_rounded,  Icons.person_rounded,
                'Profile', navHighlight),
          ],
        ),
      ),
    );
  }

  // Nav items are plain widgets (NOT Expanded) — Row uses spaceAround
  Widget _navItem(int navIndex, IconData icon, IconData activeIcon,
      String label, int navHighlight) {
    final colors   = Theme.of(context).extension<AppColors>()!;
    final isActive = navHighlight == navIndex && !_fabOpen;

    return GestureDetector(
      onTap: () => _onNavTap(navIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppTheme.primary : colors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isActive ? AppTheme.primary : colors.textSecondary,
                )),
            ],
          ),
      ),
    );
  }
}

// ── Animated FAB popup option ─────────────────
class _FabOption extends StatelessWidget {
  final String             label;
  final IconData           icon;
  final Color              color;
  final AnimationController anim;
  final Interval           interval;
  final AppColors          colors;
  final VoidCallback       onTap;

  const _FabOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.anim,
    required this.interval,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = interval.transform(anim.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + 0.3 * t,
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - t)),
              child: GestureDetector(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text(label,
                        style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: colors.textPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
