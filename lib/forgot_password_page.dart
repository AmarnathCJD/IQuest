import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'services/auth_service.dart';
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('Please enter your email address.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.forgotPassword(email: email);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSuccessDialog(
        result['message'] ?? 'Password reset link has been sent to your email!',
        () {
          Navigator.pop(context);
        },
      );
    } else {
      _showErrorDialog(result['message'] ?? 'Failed to process request.');
      setState(() => _isLoading = false);
    }
  }
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }
  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.earth,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
  void _showSuccessDialog(String message, VoidCallback onClose) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.moss,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
    Future.delayed(const Duration(seconds: 2), onClose);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: OrganicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.moss.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: AppTheme.moss,
                      size: 28,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOutBack,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
              const SizedBox(height: 12),
              Text(
                    'Restore\naccess.',
                    style: Theme.of(context).textTheme.displayLarge,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              Text(
                    'We all stray from the path occasionally. We will help you find your way back.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms, delay: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Account Email Address',
                ),
              ).animate().fadeIn(duration: 1000.ms, delay: 600.ms),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child:
                        ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleForgotPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.moss,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.8),
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('RESTORE ACCESS'),
                            )
                            .animate()
                            .fadeIn(duration: 1000.ms, delay: 800.ms)
                            .animate(
                              onPlay: (c) => c.repeat(reverse: !_isLoading),
                            )
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.02, 1.02),
                              duration: 2.seconds,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
