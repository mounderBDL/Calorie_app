import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _mealCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db   = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    final userId = auth.currentUserId ?? '';
    final logs = await db.getMealHistory(userId: userId);
    if (mounted) setState(() => _mealCount = logs.length);
  }

  // ── Update display name ──────────────────────
  void _showUpdateNameDialog() {
    final ctrl = TextEditingController(
        text: FirebaseAuth.instance.currentUser?.displayName ?? '');
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        title: 'Update Name',
        icon: Icons.person_outline_rounded,
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              style: GoogleFonts.dmSans(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Your full name',
                hintStyle: GoogleFonts.dmSans(fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    size: 20, color: AppTheme.primary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) { return; }
                  await FirebaseAuth.instance.currentUser
                      ?.updateDisplayName(ctrl.text.trim());
                  if (!mounted) { return; }
                  Navigator.pop(context);
                  _showSnack('Name updated successfully ✅');
                  setState(() {});
                },
                child: Text('Save',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Update password ──────────────────────────
  void _showUpdatePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => _StyledDialog(
          title: 'Change Password',
          icon: Icons.lock_outline_rounded,
          child: Column(
            children: [
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(error!,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.red)),
                ),
              _passField(currentCtrl, 'Current password', obscureCurrent,
                  () => setLocal(() => obscureCurrent = !obscureCurrent)),
              const SizedBox(height: 12),
              _passField(newCtrl, 'New password', obscureNew,
                  () => setLocal(() => obscureNew = !obscureNew)),
              const SizedBox(height: 12),
              _passField(confirmCtrl, 'Confirm new password', obscureConfirm,
                  () => setLocal(() => obscureConfirm = !obscureConfirm)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newCtrl.text != confirmCtrl.text) {
                      setLocal(() => error = 'Passwords do not match');
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      setLocal(() => error = 'Password must be at least 6 characters');
                      return;
                    }
                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      final cred = EmailAuthProvider.credential(
                        email:    user.email!,
                        password: currentCtrl.text,
                      );
                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newCtrl.text);
                      if (!mounted) { return; }
                      Navigator.pop(ctx);
                      _showSnack('Password updated successfully ✅');
                    } on FirebaseAuthException catch (e) {
                      setLocal(() => error = e.message ?? 'Error occurred');
                    }
                  },
                  child: Text('Update Password',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint, bool obscure,
      VoidCallback toggle) =>
    TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18),
          onPressed: toggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );

  // ── Daily calorie goal ───────────────────────
  void _showCalorieGoalDialog() {
    final prefs = context.read<PreferencesService>();
    final ctrl  = TextEditingController(text: '${prefs.dailyCalorieGoal}');
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        title: 'Daily Calorie Goal',
        icon:  Icons.local_fire_department_outlined,
        child: Column(
          children: [
            TextField(
              controller:   ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.dmSans(fontSize: 15),
              decoration: InputDecoration(
                hintText: '500 – 10000 kcal',
                hintStyle: GoogleFonts.dmSans(fontSize: 14),
                prefixIcon: const Icon(Icons.local_fire_department_outlined,
                    size: 20, color: AppTheme.primary),
                suffixText: 'kcal',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final val = int.tryParse(ctrl.text.trim());
                  if (val == null) return;
                  await prefs.setDailyCalorieGoal(val);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _showSnack('Calorie goal updated to $val kcal ✅');
                },
                child: Text('Save',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Generic macro goal dialog ─────────────────
  void _showMacroGoalDialog({
    required String   title,
    required IconData icon,
    required int      current,
    required String   hint,
    required String   unit,
    required Future<void> Function(int) onSave,
  }) {
    final ctrl = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        title: title,
        icon:  icon,
        child: Column(
          children: [
            TextField(
              controller:   ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.dmSans(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(fontSize: 14),
                prefixIcon: Icon(icon, size: 20, color: AppTheme.primary),
                suffixText: unit,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final val = int.tryParse(ctrl.text.trim());
                  if (val == null) return;
                  await onSave(val);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _showSnack('$title updated to $val$unit ✅');
                },
                child: Text('Save',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign out ──────────────────────────────────
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        title: 'Sign Out',
        icon: Icons.logout_rounded,
        child: Column(
          children: [
            Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context)
                            .extension<AppColors>()!
                            .divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Cancel',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AuthService>().signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Sign Out',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final user   = FirebaseAuth.instance.currentUser;
    final name   = user?.displayName ?? 'User';
    final email  = user?.email ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    final joinYear = user?.metadata.creationTime?.year;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────
              Text('Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: colors.textPrimary),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ── Centered profile card ─────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    // Gradient ring avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accentWarm],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.card,
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                          child: Text(initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26, fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email,
                      style: GoogleFonts.dmSans(
                        fontSize: 13, color: colors.textSecondary)),

                    const SizedBox(height: 18),
                    Divider(color: colors.divider, height: 1),
                    const SizedBox(height: 18),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBadge(
                          label: 'Total Meals',
                          value: '$_mealCount',
                          colors: colors,
                        ),
                        Container(
                          width: 1, height: 36,
                          color: colors.divider,
                        ),
                        _StatBadge(
                          label: 'Member Since',
                          value: joinYear != null ? '$joinYear' : '—',
                          colors: colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 28),

              // ── Account section ───────────────
              _SectionTitle('Account', colors),
              const SizedBox(height: 10),

              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Update Name',
                subtitle: name,
                onTap: _showUpdateNameDialog,
                colors: colors,
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),

              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: _showUpdatePasswordDialog,
                colors: colors,
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),

              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: email,
                onTap: null,
                colors: colors,
                showArrow: false,
              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),

              const SizedBox(height: 24),

              // ── Nutrition section ─────────────
              _SectionTitle('Nutrition', colors),
              const SizedBox(height: 10),

              Builder(builder: (ctx) {
                final prefs = ctx.watch<PreferencesService>();
                return Column(children: [
                  _SettingsTile(
                    icon:     Icons.local_fire_department_outlined,
                    title:    'Daily Calorie Goal',
                    subtitle: '${prefs.dailyCalorieGoal} kcal',
                    onTap:    _showCalorieGoalDialog,
                    colors:   colors,
                  ).animate().fadeIn(delay: 275.ms).slideX(begin: 0.05),
                  _SettingsTile(
                    icon:     Icons.grain_rounded,
                    title:    'Daily Carbs Goal',
                    subtitle: '${prefs.dailyCarbGoal} g',
                    colors:   colors,
                    onTap: () => _showMacroGoalDialog(
                      title:   'Daily Carbs Goal',
                      icon:    Icons.grain_rounded,
                      current: prefs.dailyCarbGoal,
                      hint:    '10 – 1000 g',
                      unit:    'g',
                      onSave:  context.read<PreferencesService>().setDailyCarbGoal,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                  _SettingsTile(
                    icon:     Icons.fitness_center_rounded,
                    title:    'Daily Protein Goal',
                    subtitle: '${prefs.dailyProteinGoal} g',
                    colors:   colors,
                    onTap: () => _showMacroGoalDialog(
                      title:   'Daily Protein Goal',
                      icon:    Icons.fitness_center_rounded,
                      current: prefs.dailyProteinGoal,
                      hint:    '10 – 500 g',
                      unit:    'g',
                      onSave:  context.read<PreferencesService>().setDailyProteinGoal,
                    ),
                  ).animate().fadeIn(delay: 325.ms).slideX(begin: 0.05),
                  _SettingsTile(
                    icon:     Icons.water_drop_outlined,
                    title:    'Daily Fat Goal',
                    subtitle: '${prefs.dailyFatGoal} g',
                    colors:   colors,
                    onTap: () => _showMacroGoalDialog(
                      title:   'Daily Fat Goal',
                      icon:    Icons.water_drop_outlined,
                      current: prefs.dailyFatGoal,
                      hint:    '5 – 500 g',
                      unit:    'g',
                      onSave:  context.read<PreferencesService>().setDailyFatGoal,
                    ),
                  ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                ]);
              }),

              const SizedBox(height: 24),

              // ── App section ───────────────────
              _SectionTitle('App', colors),
              const SizedBox(height: 10),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About SmartDZMeal',
                subtitle: 'Version 1.0.0 — Final Year Project',
                onTap: () {},
                colors: colors,
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),

              _SettingsTile(
                icon: Icons.restaurant_outlined,
                title: 'Supported Foods',
                subtitle: '33 food classes including Algerian cuisine',
                onTap: () => _showSupportedFoods(),
                colors: colors,
              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),

              const SizedBox(height: 24),

              // ── Sign out ──────────────────────
              _SectionTitle('Session', colors),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _confirmSignOut,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('Sign Out',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: Colors.red)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.red),
                  ]),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportedFoods() {
    final foods = [
      'Couscous 🇩🇿', 'Bourek 🇩🇿', 'Chourba 🇩🇿', 'Kofta 🇩🇿',
      'Pizza', 'Burger', 'Pasta', 'Rice', 'Sandwich', 'French Fries',
      'Caesar Salad', 'Grilled Salmon', 'Sushi', 'Ramen', 'Tacos',
      'and 18 more Food-101 classes...',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 18),
              Text('Supported Foods',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: foods.map((f) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f,
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat badge ────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  const _StatBadge({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppTheme.primary)),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 12, color: colors.textSecondary,
            fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Section title ─────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final AppColors colors;
  const _SectionTitle(this.title, this.colors);

  @override
  Widget build(BuildContext context) => Text(title,
    style: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: colors.textSecondary, letterSpacing: 0.8,
    ));
}

// ── Settings tile ─────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AppColors colors;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: colors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (showArrow && onTap != null)
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colors.textSecondary),
        ]),
      ),
    );
  }
}

// ── Reusable styled dialog ────────────────────
class _StyledDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _StyledDialog({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: colors.textPrimary)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
