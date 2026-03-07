import 'package:flutter/material.dart';

class StoryEvent {
  final String type;
  final String text;
  final String? character;
  final String? avatarKey;
  final String? avatarUrl;
  final String? emotion;
  StoryEvent({
    required this.type,
    required this.text,
    this.character,
    this.avatarKey,
    this.avatarUrl,
    this.emotion,
  });
  factory StoryEvent.fromJson(Map<String, dynamic> json) {
    return StoryEvent(
      type: json['type'] ?? 'narration',
      text: json['text'] ?? '',
      character: json['character'],
      avatarKey: json['avatar_key'],
      avatarUrl: json['avatar_url'],
      emotion: json['emotion'],
    );
  }
}

class StoryChoice {
  final int id;
  final String text;
  final String consequenceHint;
  final String realWorldContext;
  final int socialImpact;
  final int resourceStability;
  final String cacheKey;
  StoryChoice({
    required this.id,
    required this.text,
    required this.consequenceHint,
    required this.realWorldContext,
    required this.socialImpact,
    required this.resourceStability,
    required this.cacheKey,
  });
  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    final impact = json['impact'] as Map<String, dynamic>? ?? {};
    return StoryChoice(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      consequenceHint: json['consequence_hint'] ?? '',
      realWorldContext: json['real_world_context'] ?? '',
      socialImpact: (impact['social_impact'] as num?)?.toInt() ?? 0,
      resourceStability: (impact['resource_stability'] as num?)?.toInt() ?? 0,
      cacheKey: json['cache_key'] ?? '',
    );
  }
}

class StoryScenario {
  final String scenarioTitle;
  final List<StoryEvent> scene;
  final int currentLayer;
  final int totalLayers;
  final String mood;
  final Color moodColor;
  final String? ambientSound;
  final String sceneLocation;
  final int? timeConstraint;
  final int intensity;
  final String consequenceText;
  final String characterReaction;
  final String sdgFact;
  final bool realismMode;
  final int currentSocialImpact;
  final int currentResourceStability;
  final List<StoryChoice> choices;
  StoryScenario({
    required this.scenarioTitle,
    required this.scene,
    required this.currentLayer,
    required this.totalLayers,
    required this.mood,
    required this.moodColor,
    this.ambientSound,
    required this.sceneLocation,
    this.timeConstraint,
    required this.intensity,
    required this.consequenceText,
    required this.characterReaction,
    required this.sdgFact,
    required this.realismMode,
    required this.currentSocialImpact,
    required this.currentResourceStability,
    required this.choices,
  });
  bool get isFinal => currentLayer >= totalLayers;
  factory StoryScenario.fromJson(Map<String, dynamic> json) {
    return StoryScenario(
      scenarioTitle: json['scenario_title'] ?? '',
      scene: (json['scene'] as List? ?? [])
          .map((e) => StoryEvent.fromJson(e))
          .toList(),
      currentLayer: json['current_layer'] ?? 1,
      totalLayers: json['total_layers'] ?? 6,
      mood: json['mood'] ?? 'hopeful',
      moodColor: _parseHexColor(json['mood_color']),
      ambientSound: json['ambient_sound'],
      sceneLocation: json['scene_location'] ?? 'Unknown Location',
      timeConstraint: json['time_constraint'],
      intensity: json['intensity'] ?? 1,
      consequenceText: json['consequence_text'] ?? '',
      characterReaction: json['character_reaction'] ?? '',
      sdgFact: json['sdg_fact'] ?? '',
      realismMode: json['realism_mode'] ?? false,
      currentSocialImpact: json['current_social_impact'] ?? 50,
      currentResourceStability: json['current_resource_stability'] ?? 50,
      choices: (json['choices'] as List? ?? [])
          .map((c) => StoryChoice.fromJson(c))
          .toList(),
    );
  }
  static Color _parseHexColor(dynamic hex) {
    if (hex == null || hex is! String || hex.isEmpty) {
      return const Color(0xFF4CAF50);
    }
    final clean = hex.replaceAll('#', '');
    try {
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return const Color(0xFF4CAF50);
  }
}

class HistoryEntry {
  final String scenarioTitle;
  final String storyText;
  final String choiceTaken;
  HistoryEntry({
    required this.scenarioTitle,
    required this.storyText,
    required this.choiceTaken,
  });
  Map<String, dynamic> toJson() => {
    'scenario_title': scenarioTitle,
    'story_text': storyText,
    'choice_taken': choiceTaken,
  };
}

class ChoiceStat {
  final int choiceId;
  final String choiceText;
  final int count;
  ChoiceStat({
    required this.choiceId,
    required this.choiceText,
    required this.count,
  });
  factory ChoiceStat.fromJson(Map<String, dynamic> json) => ChoiceStat(
    choiceId: json['choice_id'] ?? 0,
    choiceText: json['choice_text'] ?? '',
    count: json['count'] ?? 0,
  );
}

class ChoiceStatsResponse {
  final List<ChoiceStat> stats;
  ChoiceStatsResponse({required this.stats});
  factory ChoiceStatsResponse.fromJson(Map<String, dynamic> json) {
    return ChoiceStatsResponse(
      stats: (json['stats'] as List? ?? [])
          .map((s) => ChoiceStat.fromJson(s))
          .toList(),
    );
  }
}

class SdgReport {
  final String headline;
  final int sdgAlignmentScore;
  final String grade;
  final String summary;
  final List<String> whatYouCanDoIrl;
  final String shareableQuote;
  final String? ambientSound;

  SdgReport({
    required this.headline,
    required this.sdgAlignmentScore,
    required this.grade,
    required this.summary,
    required this.whatYouCanDoIrl,
    required this.shareableQuote,
    this.ambientSound,
  });

  factory SdgReport.fromJson(Map<String, dynamic> json) {
    return SdgReport(
      headline: json['headline'] ?? '',
      sdgAlignmentScore: json['sdg_alignment_score'] ?? 0,
      grade: json['grade'] ?? '?',
      summary: json['summary'] ?? '',
      whatYouCanDoIrl: List<String>.from(json['what_you_can_do_irl'] ?? []),
      shareableQuote: json['shareable_quote'] ?? '',
      ambientSound: json['ambient_sound'],
    );
  }
}
