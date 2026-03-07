import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/realworld_model.dart';
import 'auth_service.dart';

class RealworldService {
  static const String baseUrl = 'https://id.gogram.fun/api/realworld';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<RealworldScenario> getScenario(double lat, double lon) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-scenario'),
      headers: await _getHeaders(),
      body: jsonEncode({'latitude': lat, 'longitude': lon}),
    );

    if (response.statusCode == 200) {
      return RealworldScenario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to generate scenario: ${response.body}');
    }
  }

  Future<RealworldFeedback> submitResponse(
    String scenarioId,
    String userResponse,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rate-solution'),
      headers: await _getHeaders(),
      body: jsonEncode({'scenario_id': scenarioId, 'response': userResponse}),
    );

    if (response.statusCode == 200) {
      return RealworldFeedback.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to rate solution: ${response.body}');
    }
  }
}
