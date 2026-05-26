import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading  = false;
  bool _emailSent  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      setState(() => _emailSent = true);
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
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withValues(alpha: 0.15),
                  AppTheme.accent.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: colors.textPrimary),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 40),

                    if (!_emailSent) ...[
                      // Icon
                      Center(
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.20),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              color: AppTheme.primary, size: 44),
                        ),
                      ).animate().fadeIn(delay: 100.ms).scale(),

                      const SizedBox(height: 24),

                      Center(
                        child: Text('Forgot\npassword?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36, fontWeight: FontWeight.w800,
                            height: 1.2, color: colors.textPrimary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),

                      const SizedBox(height: 8),
                      Center(
                        child: Text('Enter your email and we\'ll send you a reset link.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: colors.textSecondary),
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 36),

                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
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

                      Text('Email address',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: colors.textSecondary, letterSpacing: 0.3)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: GoogleFonts.dmSans(fontSize: 14),
                          prefixIcon: Icon(Icons.email_outlined,
                              size: 20,
                              color: AppTheme.primary.withValues(alpha: 0.7)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 28),

                      _gradientButton(
                        label: 'Send Reset Link',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _sendReset,
                      ).animate().fadeIn(delay: 300.ms),
                    ] else ...[
                      // Success state
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mark_email_read_rounded,
                                    color: Color(0xFF4CAF50), size: 40),
                              ).animate().scale(duration: 500.ms,
                                  curve: Curves.elasticOut),

                              const SizedBox(height: 24),

                              Text('Check your email',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28, fontWeight: FontWeight.w700,
                                  color: colors.textPrimary),
                              ).animate().fadeIn(delay: 200.ms),

                              const SizedBox(height: 12),

                              Text(
                                'We sent a password reset link to\n${_emailCtrl.text.trim()}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14, color: colors.textSecondary,
                                  height: 1.6),
                              ).animate().fadeIn(delay: 300.ms),

                              const SizedBox(height: 40),

                              _gradientButton(
                                label: 'Back to Sign In',
                                isLoading: false,
                                onPressed: () => Navigator.pop(context),
                              ).animate().fadeIn(delay: 400.ms),

                              const SizedBox(height: 16),

                              TextButton(
                                onPressed: _sendReset,
                                child: Text('Resend email',
                                  style: GoogleFonts.dmSans(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600)),
                              ).animate().fadeIn(delay: 500.ms),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: !isLoading
                ? [AppTheme.primary, AppTheme.accentWarm]
                : [Colors.grey.shade300, Colors.grey.shade300],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: !isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(label,
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
