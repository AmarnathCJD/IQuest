class Game {
  final String id;
  final String title;
  final int sdgNumber;
  final String tagline;
  final String levelOverview;
  final List<GameCharacter> characters;
  final String bgVid;
  Game({
    required this.id,
    required this.title,
    required this.sdgNumber,
    required this.tagline,
    required this.levelOverview,
    required this.characters,
    required this.bgVid,
  });
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sdgNumber: json['sdg_number'] ?? 0,
      tagline: json['tagline'] ?? '',
      levelOverview: json['level_overview'] ?? '',
      characters: (json['characters'] as List? ?? [])
          .map((c) => GameCharacter.fromJson(c))
          .toList(),
      bgVid: json['bg_vid'] ?? '',
    );
  }
}

class GameCharacter {
  final int id;
  final String name;
  final String tagline;
  final String archetype;
  final String description;
  final String avatarUrl;
  GameCharacter({
    required this.id,
    required this.name,
    required this.tagline,
    required this.archetype,
    required this.description,
    required this.avatarUrl,
  });
  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    return GameCharacter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tagline: json['tagline'] ?? '',
      archetype: json['archetype'] ?? '',
      description: json['description'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}
