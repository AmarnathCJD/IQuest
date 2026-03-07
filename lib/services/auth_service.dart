import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://id.gogram.fun/';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  Future<Map<String, dynamic>> signup({
    required String fullname,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          data['access_token'] ?? '',
          data['refresh_token'] ?? '',
          data['user']['id'] ?? 0,
        );
        return {'success': true, 'message': 'Account created successfully!'};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          data['access_token'] ?? '',
          data['refresh_token'] ?? '',
          data['user']['id'] ?? 0,
        );
        return {'success': true, 'message': 'Login successful!'};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset link sent to your email!',
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_token': resetToken,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              'Password reset successfully! Please login with your new password.',
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static const String _userIdKey = 'user_id';

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Map<String, dynamic> _handleError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      String errorMessage = errorData['error'] ?? 'An error occurred';
      switch (response.statusCode) {
        case 400:
          if (errorMessage.contains('Email')) {
            return {
              'success': false,
              'message': 'Please enter a valid email address.',
            };
          } else if (errorMessage.contains('Password')) {
            return {
              'success': false,
              'message': 'Password must be at least 4 characters long.',
            };
          }
          return {
            'success': false,
            'message': 'Please check your input and try again.',
          };
        case 401:
          if (errorMessage.contains('credentials')) {
            return {
              'success': false,
              'message': 'Incorrect email or password. Please try again.',
            };
          } else if (errorMessage.contains('token')) {
            return {
              'success': false,
              'message': 'Session expired. Please login again.',
            };
          }
          return {
            'success': false,
            'message': 'Authentication failed. Please try again.',
          };
        case 404:
          return {
            'success': false,
            'message': 'No account found with that email address.',
          };
        case 409:
          return {
            'success': false,
            'message':
                'This email is already registered. Please login or use a different email.',
          };
        case 500:
          return {
            'success': false,
            'message': 'Server error. Please try again later.',
          };
        default:
          return {
            'success': false,
            'message': errorMessage.isNotEmpty
                ? errorMessage
                : 'Something went wrong. Please try again.',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }
}
