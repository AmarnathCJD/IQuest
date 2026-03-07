import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game_model.dart';

class GameService {
  static const String _baseUrl = 'https://id.gogram.fun/api/game';
  Future<Game?> getGame(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_game?id=$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Game.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching game: $e');
      return null;
    }
  }
}
