import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme.dart';
import 'models/multiplayer_model.dart';
import 'services/multiplayer_service.dart';
import 'multiplayer_results_page.dart';

class MultiplayerStoryPage extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String username;

  const MultiplayerStoryPage({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.username,
  });

  @override
  State<MultiplayerStoryPage> createState() => _MultiplayerStoryPageState();
}

class _MultiplayerStoryPageState extends State<MultiplayerStoryPage> {
  final _multiplayerService = MultiplayerService();
  late WebSocketChannel _channel;

  GameScenario? _currentScenario;
  int _socialImpact = 50;
  int _resourceStability = 50;
  int _remainingTime = 0;
  int? _myChoiceId;
  Map<int, int> _voteCounts = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _channel = _multiplayerService.connectToRoom(
      widget.sessionId,
      widget.userId,
      widget.username,
    );

    _channel.stream.listen((message) {
      final event = jsonDecode(message);
      _handleWsEvent(event);
    });

    _refreshStats();
  }

  Future<void> _refreshStats() async {
    try {
      final stats = await _multiplayerService.getSessionInfo(widget.sessionId);
      final me = stats.players.firstWhere(
        (p) => p.userId.toString() == widget.userId,
      );
      if (mounted) {
        setState(() {
          _socialImpact = me.socialImpact;
          _resourceStability = me.resourceStability;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing stats: $e");
    }
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    switch (event['type']) {
      case 'room_state':
        final payload = event['payload'];
        setState(() {
          _currentScenario = GameScenario.fromJson(payload['game_state']);
          _remainingTime = payload['round_time_remaining'] ?? 0;
        });
        break;

      case 'player_choice':
        final payload = event['payload'];
        final choiceId = payload['choice_id'];
        if (choiceId != null) {
          setState(() {
            _voteCounts[choiceId] = (_voteCounts[choiceId] ?? 0) + 1;
          });
        }
        break;

      case 'round_result':
        final payload = event['payload'];
        _showRoundResult(payload);
        break;

      case 'game_ended':
      case 'results':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MultiplayerResultsPage(results: event['payload'] ?? event),
          ),
        );
        break;
    }
  }

  void _showRoundResult(Map<String, dynamic> payload) {
    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'ROUND COMPLETE',
            style: GoogleFonts.outfit(
              color: AppTheme.earth,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Consensus reached. Moving to next layer.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Next: ${payload['scenario_title'] ?? 'The Journey Continues'}',
                style: TextStyle(
                  color: AppTheme.sage,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _myChoiceId = null;
                  _voteCounts = {};
                  _isProcessing = false;
                  _refreshStats();
                });
              },
              child: const Text(
                'PROCEED',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _makeChoice(int choiceId, String text) async {
    if (_myChoiceId != null || _isProcessing) return;

    // Send via WebSocket per spec
    _channel.sink.add(
      jsonEncode({
        'type': 'choice',
        'payload': {'choice_id': choiceId, 'choice_text': text},
      }),
    );

    // Also call REST if needed, but spec says WS choice is outgoing.
    // I'll call REST to be safe as well.
    try {
      await _multiplayerService.makeChoice(
        sessionId: widget.sessionId,
        choiceId: choiceId,
        choiceText: text,
      );
      setState(() => _myChoiceId = choiceId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
            child: Column(
              children: [
                _buildHUD(),
                if (_currentScenario == null)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.earth),
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildScenarioContent(),
                          const SizedBox(height: 40),
                          // Choices would normally come from scenario JSON but spec only has basic info
                          // I'll add placeholder choices for UI
                          _buildChoiceItem(1, "Sustain Current Operations"),
                          _buildChoiceItem(2, "Aggressive Expansion"),
                          _buildChoiceItem(3, "Community Outreach"),
                        ],
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
          _buildMetricCard('SOCIAL', _socialImpact, AppTheme.sage),
          _buildTimerCard(),
          _buildMetricCard('RESOURCES', _resourceStability, AppTheme.earth),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _remainingTime < 60 ? AppTheme.earth : Colors.white24,
        ),
      ),
      child: Text(
        '${(_remainingTime / 60).floor()}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
        style: TextStyle(
          color: _remainingTime < 60 ? AppTheme.earth : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 8),
          ),
          Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioContent() {
    return Column(
      children: [
        Text(
          _currentScenario!.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: AppTheme.earth,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "As the situation intensifies (Intensity: ${_currentScenario!.intensity}), your team must decide the next strategic move.",
          style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildChoiceItem(int id, String text) {
    final isSelected = _myChoiceId == id;
    final voteCount = _voteCounts[id] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _makeChoice(id, text),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.sage.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.sage : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: const TextStyle(color: Colors.white)),
              ),
              if (voteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.earth,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$voteCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
