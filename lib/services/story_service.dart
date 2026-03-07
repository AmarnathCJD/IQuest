import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story_model.dart';

class StoryService {
  static const String _baseUrl = 'https://id.gogram.fun/api/game';

  Future<StoryScenario?> beginStory({
    required String gameId,
    required int characterId,
    required bool realismMode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/begin-story'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game_id': gameId,
          'character_id': characterId,
          'realism_mode': realismMode,
        }),
      );
      if (response.statusCode == 200) {
        try {
          return StoryScenario.fromJson(jsonDecode(response.body));
        } catch (e) {
          print('JSON Parse Error in beginStory: $e');
          print('Response body: ${response.body}');
          return null;
        }
      }
      print(
        'HTTP Error ${response.statusCode} in beginStory: ${response.body}',
      );
      return null;
    } catch (e) {
      print('Error beginning story: $e');
      return null;
    }
  }

  Future<StoryScenario?> getCachedScenario(String cacheKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cached-scenario?key=$cacheKey'),
      );
      if (response.statusCode == 200) {
        try {
          return StoryScenario.fromJson(jsonDecode(response.body));
        } catch (e) {
          print('JSON Parse Error in cached-scenario: $e');
          print('Response body: ${response.body}');
          return null;
        }
      }
      return null; // Might be 404 pending, don't flood logs
    } catch (e) {
      print('Error fetching cached story: $e');
      return null;
    }
  }

  Future<StoryScenario?> continueStory({
    required String gameId,
    required int characterId,
    required int choiceId,
    required String choiceText,
    required String cacheKey,
    required bool realismMode,
    required List<HistoryEntry> history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/continue-story'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game_id': gameId,
          'character_id': characterId,
          'choice_id': choiceId,
          'choice_text': choiceText,
          'cache_key': cacheKey,
          'realism_mode': realismMode,
          'history': history.map((h) => h.toJson()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        try {
          return StoryScenario.fromJson(jsonDecode(response.body));
        } catch (e) {
          print('JSON Parse Error in continueStory: $e');
          print('Response body: ${response.body}');
          return null;
        }
      }
      print(
        'HTTP Error ${response.statusCode} in continueStory: ${response.body}',
      );
      return null;
    } catch (e) {
      print('Error continuing story: $e');
      return null;
    }
  }

  Future<ChoiceStatsResponse?> fetchChoiceStats({
    required String gameId,
    required int layer,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/choice-stats?game_id=$gameId&layer=$layer'),
      );
      if (response.statusCode == 200) {
        return ChoiceStatsResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching choice stats: $e');
      return null;
    }
  }

  Future<SdgReport?> fetchSdgReport({
    required String gameId,
    required int characterId,
    required List<HistoryEntry> history,
    required Map<String, int> finalScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sdg-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game_id': gameId,
          'character_id': characterId,
          'history': history.map((h) => h.toJson()).toList(),
          'final_score': finalScore,
        }),
      );
      if (response.statusCode == 200) {
        return SdgReport.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching SDG report: $e');
      return null;
    }
  }
}
