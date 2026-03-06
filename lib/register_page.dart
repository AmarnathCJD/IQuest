import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'home_page.dart';
import 'services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (fullname.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    if (fullname.length < 2) {
      _showErrorDialog('Full name must be at least 2 characters long.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    if (password.length < 4) {
      _showErrorDialog('Password must be at least 4 characters long.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signup(
      fullname: fullname,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccessDialog('Account created! Welcome aboard! 🌱', () {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 1000),
          ),
          (route) => false,
        );
      });
    } else {
      _showErrorDialog(result['message'] ?? 'Sign up failed.');
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
      body: OrganicBackgroundSignUp(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.earth.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: AppTheme.earth,
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
                    'Sow the\nfirst seed.',
                    style: Theme.of(context).textTheme.displayLarge,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 8),

              Text(
                    'Join our collective to shape sustainable solutions and impact the environment deeply.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms, delay: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              TextField(
                controller: _fullnameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ).animate().fadeIn(duration: 1000.ms, delay: 600.ms),

              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ).animate().fadeIn(duration: 1000.ms, delay: 750.ms),

              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Secure Password (min 4 chars)',
                ),
              ).animate().fadeIn(duration: 1000.ms, delay: 900.ms),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child:
                        ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.earth,
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
                                  : const Text('JOIN THE EFFORT'),
                            )
                            .animate()
                            .fadeIn(duration: 1000.ms, delay: 1100.ms)
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
