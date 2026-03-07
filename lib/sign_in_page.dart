import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}
class _SignInPageState extends State<SignInPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _handleLogin() async {
    _showSuccessDialog('Debug Mode: Login Bypassed', () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
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
      body: OrganicBackgroundEnhanced(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 112.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.sage.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppTheme.forest,
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
                    const SizedBox(height: 16),
                    Text(
                          'Ready to\nchange the world?',
                          style: Theme.of(context).textTheme.displayLarge,
                        )
                        .animate()
                        .fadeIn(duration: 1500.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 8),
                    Text(
                          'Step into the stewardship of our planet.\nNavigate real-world social and ecological challenges.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                        .animate()
                        .fadeIn(duration: 1500.ms, delay: 500.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                    ).animate().fadeIn(duration: 1000.ms, delay: 700.ms),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ).animate().fadeIn(duration: 1000.ms, delay: 850.ms),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white.withOpacity(
                                                      0.8,
                                                    ),
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('ENTER SUSTAINABLE QUEST'),
                                  )
                                  .animate()
                                  .fadeIn(duration: 1000.ms, delay: 1000.ms)
                                  .animate(
                                    onPlay: (c) =>
                                        c.repeat(reverse: !_isLoading),
                                  )
                                  .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.02, 1.02),
                                    duration: 2.seconds,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const RegisterPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                              ),
                            );
                          },
                          child: const Text('BEGIN YOUR JOURNEY'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const ForgotPasswordPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                              ),
                            );
                          },
                          child: const Text('FORGOT ACCESS?'),
                        ),
                      ],
                    ).animate().fadeIn(duration: 1000.ms, delay: 1150.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
