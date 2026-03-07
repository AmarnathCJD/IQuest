import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/multiplayer_model.dart';
import 'auth_service.dart';

class MultiplayerService {
  static const String baseUrl = 'https://id.gogram.fun/api/multiplayer';
  static const String wsUrl = 'wss://id.gogram.fun/ws/multiplayer';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<GameSession> createSession({
    required String gameId,
    required int maxPlayers,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-session'),
      headers: await _getHeaders(),
      body: jsonEncode({'game_id': gameId, 'max_players': maxPlayers}),
    );

    if (response.statusCode == 201) {
      return GameSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create session: ${response.body}');
    }
  }

  Future<void> joinSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/join-session'),
      headers: await _getHeaders(),
      body: jsonEncode({'session_id': sessionId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join session: ${response.body}');
    }
  }

  Future<GameSession> getSessionInfo(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/session-info?session_id=$sessionId'),
    );

    if (response.statusCode == 200) {
      return GameSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get session info: ${response.body}');
    }
  }

  Future<void> makeChoice({
    required String sessionId,
    required int choiceId,
    required String choiceText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/make-choice'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'session_id': sessionId,
        'choice_id': choiceId,
        'choice_text': choiceText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to make choice: ${response.body}');
    }
  }

  Future<void> startRound(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/start-round'),
      headers: await _getHeaders(),
      body: jsonEncode({'session_id': sessionId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start round: ${response.body}');
    }
  }

  WebSocketChannel connectToRoom(
    String sessionId,
    String userId,
    String username,
  ) {
    return WebSocketChannel.connect(
      Uri.parse(
        '$wsUrl?session_id=$sessionId&user_id=$userId&username=${Uri.encodeComponent(username)}',
      ),
    );
  }

  Future<List<GameSession>> listSessions(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/list-sessions?game_id=$gameId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['sessions'] as List)
          .map((s) => GameSession.fromJson(s))
          .toList();
    } else {
      throw Exception('Failed to list sessions: ${response.body}');
    }
  }
}
