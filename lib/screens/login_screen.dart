import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool _obscure      = true;
  bool _isLoading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = context.read<AuthService>();
      await auth.signIn(
        email:    _emailCtrl.text,
        password: _passCtrl.text,
      );
      // AuthWrapper handles navigation automatically
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = context.read<AuthService>().getErrorMessage(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primary.withOpacity(0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withOpacity(0.12),
                  AppTheme.accent.withOpacity(0.0),
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
                    const SizedBox(height: 52),

                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.restaurant_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text('SmartDZMeal',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          )),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                    const SizedBox(height: 48),

                    // Title
                    Text('Welcome\nback 👋',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38, fontWeight: FontWeight.w700,
                        height: 1.2, color: colors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms)
                                .slideY(begin: 0.15),

                    const SizedBox(height: 8),
                    Text('Sign in to continue tracking your meals',
                      style: GoogleFonts.dmSans(
                        fontSize: 14, color: colors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                    const SizedBox(height: 40),

                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13, color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                )),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).shake(),

                    // Email field
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
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 18),

                    // Password field
                    _buildLabel('Password', colors),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        '••••••••', Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textSecondary, size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                    const SizedBox(height: 32),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('Sign In',
                                style: GoogleFonts.dmSans(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Forgot password link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen())),
                        child: Text('Forgot password?',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                      ),
                    ).animate().fadeIn(delay: 320.ms),

                    const SizedBox(height: 16),

                    // Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: colors.textSecondary),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign up',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

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
      color: colors.textSecondary, letterSpacing: 0.3,
    ));

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.7)),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
}
