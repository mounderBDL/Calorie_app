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
                  AppTheme.accent.withOpacity(0.15),
                  AppTheme.accent.withOpacity(0.0),
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
                          border: Border.all(color: colors.divider),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: colors.textPrimary),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 40),

                    if (!_emailSent) ...[
                      // Icon
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: AppTheme.primary, size: 32),
                      ).animate().fadeIn(delay: 100.ms).scale(),

                      const SizedBox(height: 24),

                      Text('Forgot\npassword?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          height: 1.2, color: colors.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),

                      const SizedBox(height: 8),
                      Text('Enter your email and we\'ll send you a reset link.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: colors.textSecondary),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 36),

                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                              color: AppTheme.primary.withOpacity(0.7)),
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

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendReset,
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
                              : Text('Send Reset Link',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ] else ...[
                      // Success state
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mark_email_read_rounded,
                                  color: Color(0xFF4CAF50), size: 40),
                            ).animate().scale(duration: 500.ms,
                                curve: Curves.elasticOut),

                            const SizedBox(height: 24),

                            Text('Check your email',
                              style: GoogleFonts.playfairDisplay(
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

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                ),
                                child: Text('Back to Sign In',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              ),
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
}
