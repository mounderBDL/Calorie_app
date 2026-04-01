import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = context.read<AuthService>();
      await auth.signUp(
        email:    _emailCtrl.text,
        password: _passCtrl.text,
        name:     _nameCtrl.text,
      );
      if (!mounted) return;
      // Show success dialog
      await _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = context.read<AuthService>().getErrorMessage(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated checkmark
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 44),
              ).animate().scale(
                  duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 20),

              Text('Account Created!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: colors.textPrimary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Welcome to SmartDZMeal,\n${_nameCtrl.text.trim().split(' ').first}! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: colors.textSecondary,
                  height: 1.5),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    // AuthWrapper will auto-navigate to MainScreen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Get Started',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withOpacity(0.15),
                  AppTheme.accent.withOpacity(0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withOpacity(0.12),
                  AppTheme.primary.withOpacity(0.0),
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: colors.textPrimary),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    Text('Create\naccount 🍽',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38, fontWeight: FontWeight.w700,
                        height: 1.2, color: colors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15),

                    const SizedBox(height: 8),
                    Text('Start tracking your meals and nutrition today',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: colors.textSecondary),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 36),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13, color: Colors.red,
                              fontWeight: FontWeight.w500))),
                        ]),
                      ).animate().fadeIn().shake(),

                    _buildLabel('Full name', colors),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                          'Your name', Icons.person_outline_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required' : null,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    _buildLabel('Email address', colors),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                          'you@example.com', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 16),

                    _buildLabel('Password', colors),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        '••••••••', Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textSecondary, size: 20),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 16),

                    _buildLabel('Confirm password', colors),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        '••••••••', Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textSecondary, size: 20),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please confirm your password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text('Create Account',
                                style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: colors.textSecondary),
                            children: [
                              const TextSpan(
                                  text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, AppColors colors) => Text(text,
    style: GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: colors.textSecondary, letterSpacing: 0.3));

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14),
      prefixIcon: Icon(icon, size: 20,
          color: AppTheme.primary.withOpacity(0.7)),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
    );
}
