import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme.dart';
import 'models/multiplayer_model.dart';
import 'services/multiplayer_service.dart';
import 'multiplayer_story_page.dart';

class MultiplayerLobbyPage extends StatefulWidget {
  final GameSession session;
  final String username;
  final String userId;

  const MultiplayerLobbyPage({
    super.key,
    required this.session,
    required this.username,
    required this.userId,
  });

  @override
  State<MultiplayerLobbyPage> createState() => _MultiplayerLobbyPageState();
}

class _MultiplayerLobbyPageState extends State<MultiplayerLobbyPage> {
  late GameSession _currentSession;
  late WebSocketChannel _channel;
  final _multiplayerService = MultiplayerService();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _channel = _multiplayerService.connectToRoom(
      _currentSession.sessionId,
      widget.userId,
      widget.username,
    );

    _channel.stream.listen((message) {
      final event = jsonDecode(message);
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    setState(() {
      if (event['type'] == 'player_joined' ||
          event['type'] == 'player_left' ||
          event['type'] == 'player_ready') {
        _refreshSession();
      }

      if (event['type'] == 'room_state') {
        final payload = event['payload'];
        if (payload['status'] == 'active') {
          _navigateToStory();
        }
      }
    });
  }

  Future<void> _refreshSession() async {
    try {
      final updated = await _multiplayerService.getSessionInfo(
        _currentSession.sessionId,
      );
      if (mounted) setState(() => _currentSession = updated);
    } catch (e) {
      debugPrint("Error refreshing session: $e");
    }
  }

  void _navigateToStory() {
    // In a real flow, we'd get the scenario from room_state
    // For now, I'll use a placeholder or wait for the start_round response
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerStoryPage(
          sessionId: _currentSession.sessionId,
          userId: widget.userId,
          username: widget.username,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _toggleReady() {
    final newReady = !_isReady;
    _channel.sink.add(
      jsonEncode({
        'type': 'ready',
        'payload': {'is_ready': newReady},
      }),
    );
    setState(() => _isReady = newReady);
  }

  Future<void> _startGame() async {
    try {
      await _multiplayerService.startRound(_currentSession.sessionId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.userId == _currentSession.hostId.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.earth.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.earth.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      'SESSION: ${_currentSession.sessionId.substring(0, 8)}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.earth,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'SQUAD ASSEMBLED',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${_currentSession.players.length}/${_currentSession.maxPlayers} PLAYERS',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              Expanded(
                child: ListView.builder(
                  itemCount: _currentSession.players.length,
                  itemBuilder: (context, index) {
                    final player = _currentSession.players[index];
                    return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: player.isReady
                                  ? AppTheme.sage.withOpacity(0.3)
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.earth.withOpacity(
                                  0.2,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (player.userId == _currentSession.hostId)
                                      const Text(
                                        'HOST',
                                        style: TextStyle(
                                          color: AppTheme.earth,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (player.isReady)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.sage,
                                )
                              else
                                const Text(
                                  'NOT READY',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _toggleReady,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isReady
                            ? AppTheme.sage
                            : Colors.white12,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Text(
                        _isReady ? 'READY!' : 'MARK AS READY',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.earth,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'START MISSION',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
