import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme.dart';
import 'models/story_model.dart';
import 'models/game_model.dart';

class SdgReportPage extends StatefulWidget {
  final SdgReport report;
  final GameCharacter character;
  final String gameId;

  const SdgReportPage({
    super.key,
    required this.report,
    required this.character,
    required this.gameId,
  });

  @override
  State<SdgReportPage> createState() => _SdgReportPageState();
}

class _SdgReportPageState extends State<SdgReportPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startMusic();
  }

  void _startMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    final sound = widget.report.ambientSound ?? _getSituationalSound();
    await _audioPlayer.play(
      UrlSource('https://id.gogram.fun/assets/audio/$sound.mp3'),
    );
  }

  String _getSituationalSound() {
    final grade = widget.report.grade.toUpperCase();
    if (grade.contains('A')) return 'success'; // Triumphant for high scores
    if (grade.contains('B')) return 'hopeful'; // Positive but moderate
    if (grade.contains('C')) return 'neutral'; // Reflective
    return 'tense'; // Somber/Urgent for low scores
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _shareQuote(BuildContext context) async {
    final text = '${widget.report.shareableQuote} — #SDGs';
    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}',
    );

    // Copy to clipboard fallback
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quote copied!', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      // Ignore if twitter can't open
    }
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A+')) return Colors.green.shade600;
    if (grade.startsWith('A')) return Colors.blue.shade600;
    if (grade.startsWith('B')) return Colors.amber.shade600;
    if (grade.startsWith('C')) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(widget.report.grade);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://yj73xzxbti.ucarecd.net/20b504eb-a43f-4f95-ab59-5bfeeb740570/-/preview/557x1000/',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for readability (instead of blur)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Headline
                  Text(
                        widget.report.headline.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.balsamiqSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 32),

                  // Grade & Score Card (Glassmorphic)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.report.grade,
                                  style: GoogleFonts.balsamiqSans(
                                    fontSize: 84,
                                    fontWeight: FontWeight.w700,
                                    color: gradeColor,
                                    height: 1,
                                    shadows: [
                                      Shadow(
                                        color: gradeColor.withOpacity(0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'GRADE',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ).animate().scale(
                              delay: 400.ms,
                              curve: Curves.elasticOut,
                              duration: 800.ms,
                            ),
                            const SizedBox(height: 28),

                            // Progress Bar
                            ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value:
                                        widget.report.sdgAlignmentScore / 100.0,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    color: gradeColor,
                                    minHeight: 12,
                                  ),
                                )
                                .animate()
                                .slideX(begin: -0.2, end: 0, delay: 600.ms)
                                .fadeIn(),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alignment Score',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${widget.report.sdgAlignmentScore}/100',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: gradeColor,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 800.ms),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.report.summary,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 48),

                  // What You Can Do IRL
                  if (widget.report.whatYouCanDoIrl.isNotEmpty) ...[
                    Text(
                      'Actions IRL',
                      style: GoogleFonts.quicksand(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...widget.report.whatYouCanDoIrl
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.amberAccent,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Text(
                                          action,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 48),
                  ],

                  // Shareable Quote
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradeColor.withOpacity(0.8),
                          gradeColor.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: gradeColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 44,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '"${widget.report.shareableQuote}"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.balsamiqSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => _shareQuote(context),
                          icon: Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: gradeColor,
                          ),
                          label: Text(
                            'SHARE IMPACT',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w900,
                              color: gradeColor,
                              letterSpacing: 2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: gradeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Done
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 64),
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'RETURN TO HUB',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ).animate().fadeIn(duration: 800.ms),
            ),
          ),
        ],
      ),
    );
  }
}
