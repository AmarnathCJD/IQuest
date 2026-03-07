import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';

class MultiplayerResultsPage extends StatelessWidget {
  final Map<String, dynamic> results;

  const MultiplayerResultsPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final players = (results['players'] as List? ?? []);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'COLLECTIVE OUTCOME',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'FINAL SCOREBOARD',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 40),

              // Grade Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.earth.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.earth),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TEAM GRADE',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      results['final_grade'] ?? 'B',
                      style: GoogleFonts.outfit(
                        color: AppTheme.earth,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 48),

              // Leaderboard
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final rank = index + 1;
                    return _buildRankCard(player, rank);
                  },
                ),
              ),

              // Exit
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.earth,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text(
                  'RETURN TO BASE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> player, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank == 1 ? AppTheme.sage.withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppTheme.sage : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['username'] ?? 'Anonymous',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  player['character_name'] ?? 'Survivor',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${player['score']} PTS',
            style: const TextStyle(
              color: AppTheme.sage,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
