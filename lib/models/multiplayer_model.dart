class GameSession {
  final String sessionId;
  final String gameId;
  final String status;
  final int maxPlayers;
  final int hostId;
  final int currentRound;
  final List<SessionPlayer> players;
  final DateTime createdAt;

  GameSession({
    required this.sessionId,
    required this.gameId,
    required this.status,
    required this.maxPlayers,
    required this.hostId,
    required this.currentRound,
    required this.players,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['session_id'] ?? '',
      gameId: json['game_id'] ?? '',
      status: json['status'] ?? 'waiting',
      maxPlayers: json['max_players'] ?? 0,
      hostId: json['host_id'] ?? 0,
      currentRound: json['current_round'] ?? 0,
      players: (json['players'] as List? ?? [])
          .map((p) => SessionPlayer.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class SessionPlayer {
  final int userId;
  final String username;
  final int score;
  final int currentLayer;
  final int socialImpact;
  final int resourceStability;
  final String status;
  final bool isReady;

  SessionPlayer({
    required this.userId,
    required this.username,
    required this.score,
    required this.currentLayer,
    required this.socialImpact,
    required this.resourceStability,
    required this.status,
    this.isReady = false,
  });

  factory SessionPlayer.fromJson(Map<String, dynamic> json) {
    return SessionPlayer(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      score: json['score'] ?? 0,
      currentLayer: json['current_layer'] ?? 0,
      socialImpact: json['social_impact'] ?? 50,
      resourceStability: json['resource_stability'] ?? 50,
      status: json['status'] ?? 'active',
      isReady: json['is_ready'] ?? false,
    );
  }
}

class GameScenario {
  final String title;
  final int intensity;
  final int timeLimitMinutes;

  GameScenario({
    required this.title,
    required this.intensity,
    required this.timeLimitMinutes,
  });

  factory GameScenario.fromJson(Map<String, dynamic> json) {
    return GameScenario(
      title: json['scenario_title'] ?? '',
      intensity: json['intensity'] ?? 5,
      timeLimitMinutes: json['time_limit_minutes'] ?? 15,
    );
  }
}
