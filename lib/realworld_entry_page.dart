import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'services/realworld_service.dart';
import 'realworld_game_page.dart';

class RealworldEntryPage extends StatefulWidget {
  const RealworldEntryPage({super.key});

  @override
  State<RealworldEntryPage> createState() => _RealworldEntryPageState();
}

class _RealworldEntryPageState extends State<RealworldEntryPage> {
  final _realworldService = RealworldService();
  bool _isLoading = false;
  String _status = "Waiting for location...";

  Future<void> _startRealworldMode() async {
    setState(() {
      _isLoading = true;
      _status = "Detecting your coordinates...";
    });

    try {
      final position = await _realworldService.getCurrentLocation();

      setState(() {
        _status = "Generating scenario for your location...";
      });

      final scenario = await _realworldService.getScenario(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RealworldGamePage(scenario: scenario),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'REAL-WORLD MODE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transform your actual surroundings into a Vitalis mission. Our AI will analyze your local geography to craft a unique story.',
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),

                  if (_isLoading) ...[
                    const Center(
                      child: CircularProgressIndicator(color: AppTheme.earth),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: AppTheme.earth,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _startRealworldMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.earth,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 72),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                      child: Text(
                        'INITIATE SCAN',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ).animate().scale(delay: 200.ms),
                  ],

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
