import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'models/multiplayer_model.dart';
import 'services/multiplayer_service.dart';
import 'services/auth_service.dart';
import 'multiplayer_lobby_page.dart';

class MultiplayerEntryPage extends StatefulWidget {
  const MultiplayerEntryPage({super.key});

  @override
  State<MultiplayerEntryPage> createState() => _MultiplayerEntryPageState();
}

class _MultiplayerEntryPageState extends State<MultiplayerEntryPage> {
  final _multiplayerService = MultiplayerService();
  final _authService = AuthService();

  bool _isLoading = false;
  List<GameSession> _sessions = [];
  String _username = "Explorer";

  @override
  void initState() {
    super.initState();
    _loadUsernameAndSessions();
  }

  Future<void> _loadUsernameAndSessions() async {
    setState(() => _isLoading = true);
    try {
      // For now, use a default game ID
      _sessions = await _multiplayerService.listSessions('vitalis_good_health');
      // In a real app, get username from profile
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createSession() async {
    setState(() => _isLoading = true);
    try {
      final session = await _multiplayerService.createSession(
        gameId: 'vitalis_good_health',
        maxPlayers: 4,
      );
      _joinSession(session.sessionId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinSession(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      await _multiplayerService.joinSession(sessionId);
      final sessionInfo = await _multiplayerService.getSessionInfo(sessionId);
      final userId = await _authService.getUserId();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerLobbyPage(
              session: sessionInfo,
              username: _username,
              userId: userId.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              opacity: 0.5,
              child: Image.asset('assets/char.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'MULTIPLAYER',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 40),

                  _buildSectionHeader('ACTIVE SESSIONS'),

                  const SizedBox(height: 16),

                  Expanded(
                    child: _isLoading && _sessions.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.earth,
                            ),
                          )
                        : _sessions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final s = _sessions[index];
                              return _buildSessionCard(s);
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.earth,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'CREATE NEW SESSION',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Colors.white10)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          Text(
            'NO ACTIVE SESSIONS FOUND',
            style: GoogleFonts.outfit(
              color: Colors.white24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(GameSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION: ${s.gameId.replaceAll('_', ' ').toUpperCase()}',
                  style: GoogleFonts.outfit(
                    color: AppTheme.earth,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'ID: ${s.sessionId.substring(0, 8)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Players: ${s.players.length}/${s.maxPlayers}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _joinSession(s.sessionId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sage,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('JOIN'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
