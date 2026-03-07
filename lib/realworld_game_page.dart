import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'models/realworld_model.dart';
import 'services/realworld_service.dart';

class RealworldGamePage extends StatefulWidget {
  final RealworldScenario scenario;

  const RealworldGamePage({super.key, required this.scenario});

  @override
  State<RealworldGamePage> createState() => _RealworldGamePageState();
}

class _RealworldGamePageState extends State<RealworldGamePage> {
  final _realworldService = RealworldService();
  final _controller = TextEditingController();
  bool _isLoading = false;
  RealworldFeedback? _feedback;
  int _socialImpact = 50;
  int _resourceStability = 50;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final feedback = await _realworldService.submitResponse(
        widget.scenario.title, // In a real app, this would be a scenario ID
        _controller.text,
      );

      setState(() {
        _feedback = feedback;
        _socialImpact = (_socialImpact + feedback.impactSocial).clamp(0, 100);
        _resourceStability = (_resourceStability + feedback.impactResource)
            .clamp(0, 100);
      });

      _showFeedbackDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedbackDialog() {
    if (_feedback == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Text(
            'MISSION RATING: ${_feedback!.rating}/10',
            style: GoogleFonts.outfit(
              color: AppTheme.earth,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _feedback!.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CRITICAL LEARNING:',
                        style: TextStyle(
                          color: AppTheme.sage,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _feedback!.educationalContent,
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDeltaStat('SI', _feedback!.impactSocial),
                    _buildDeltaStat('RS', _feedback!.impactResource),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                'END MISSION',
                style: GoogleFonts.outfit(
                  color: AppTheme.earth,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaStat(String label, int delta) {
    final color = delta >= 0 ? AppTheme.sage : AppTheme.earth;
    final sign = delta >= 0 ? '+' : '';
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          '$sign$delta',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/char.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHUD(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          _buildStoryCard(),
                          const SizedBox(height: 32),
                          _buildInputSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricCard('SOCIAL IMPACT', _socialImpact, AppTheme.sage),
          _buildMetricCard(
            'RESOURCE STABILITY',
            _resourceStability,
            AppTheme.earth,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.earth.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.earth.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: AppTheme.earth, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.scenario.placeName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.earth,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.scenario.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.scenario.description,
            style: GoogleFonts.quicksand(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            widget.scenario.initialPrompt,
            style: GoogleFonts.outfit(
              color: AppTheme.sage,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type your solution here...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(24),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitResponse,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.earth,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 8,
            shadowColor: AppTheme.earth.withOpacity(0.5),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'SUBMIT RESPONSE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ],
    );
  }
}
