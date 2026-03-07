class RealworldScenario {
  final String title;
  final String description;
  final String placeName;
  final Map<String, dynamic> siteFacts;
  final String initialPrompt;

  RealworldScenario({
    required this.title,
    required this.description,
    required this.placeName,
    required this.siteFacts,
    required this.initialPrompt,
  });

  factory RealworldScenario.fromJson(Map<String, dynamic> json) {
    return RealworldScenario(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      placeName: json['place_name'] ?? '',
      siteFacts: Map<String, dynamic>.from(json['site_facts'] ?? {}),
      initialPrompt: json['initial_prompt'] ?? '',
    );
  }
}

class RealworldFeedback {
  final int rating;
  final String message;
  final String educationalContent;
  final int impactSocial;
  final int impactResource;

  RealworldFeedback({
    required this.rating,
    required this.message,
    required this.educationalContent,
    required this.impactSocial,
    required this.impactResource,
  });

  factory RealworldFeedback.fromJson(Map<String, dynamic> json) {
    return RealworldFeedback(
      rating: json['rating'] ?? 0,
      message: json['message'] ?? '',
      educationalContent: json['educational_content'] ?? '',
      impactSocial: json['impact_social'] ?? 0,
      impactResource: json['impact_resource'] ?? 0,
    );
  }
}
