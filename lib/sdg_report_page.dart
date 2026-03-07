import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'models/story_model.dart';
import 'models/game_model.dart';

class SdgReportPage extends StatelessWidget {
  final SdgReport report;
  final GameCharacter character;
  final String gameId;

  const SdgReportPage({
    super.key,
    required this.report,
    required this.character,
    required this.gameId,
  });

  Future<void> _shareQuote(BuildContext context) async {
    final text = '${report.shareableQuote} — #SDGs';
    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}',
    );

    // Copy to clipboard fallback
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote copied!', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forest,
        behavior: SnackBarBehavior.floating,
      ),
    );

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
    final gradeColor = _getGradeColor(report.grade);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Headline
              Text(
                report.headline.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.balsamiqSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forest,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 32),

              // Grade & Score Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.sage.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          report.grade,
                          style: GoogleFonts.balsamiqSans(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: gradeColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'GRADE',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.earth,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ).animate().scale(
                      delay: 400.ms,
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),
                    const SizedBox(height: 24),

                    // Progress Bar
                    ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: report.sdgAlignmentScore / 100.0,
                            backgroundColor: AppTheme.sage.withOpacity(0.2),
                            color: gradeColor,
                            minHeight: 12,
                          ),
                        )
                        .animate()
                        .slideX(begin: -0.2, end: 0, delay: 600.ms)
                        .fadeIn(),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alignment Score',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.sage,
                          ),
                        ),
                        Text(
                          '${report.sdgAlignmentScore}/100',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: gradeColor,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  report.summary,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.forest.withOpacity(0.85),
                    height: 1.6,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 48),

              // What You Can Do IRL
              if (report.whatYouCanDoIrl.isNotEmpty) ...[
                Text(
                  'Actions IRL',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(height: 16),
                ...report.whatYouCanDoIrl
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.sage.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: AppTheme.earth,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  action,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.forest.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.forest, AppTheme.moss],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 40,
                      color: const Color(0xFFF9F6F0),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${report.shareableQuote}"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.balsamiqSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _shareQuote(context),
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: AppTheme.forest,
                      ),
                      label: Text(
                        'Share on Social',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forest,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Done
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  backgroundColor: AppTheme.forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.forest.withOpacity(0.4),
                ),
                child: Text(
                  'RETURN TO HUB',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ).animate().fadeIn(duration: 800.ms),
        ),
      ),
    );
  }
}
