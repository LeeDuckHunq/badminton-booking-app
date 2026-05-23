import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool('remember_login') ?? false;
    if (!remember) {
      await logout();
      return false;
    }

    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) return false;

    if (JwtDecoder.isExpired(token)) {
      await logout();
      return false;
    }

    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('remember_login');
  }
}