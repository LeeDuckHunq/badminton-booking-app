import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;

class AccountApi {
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("${ServerAddress().address}/login"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", data['token'] as String);
        await prefs.setString("username", data['username'] as String? ?? username);
        await prefs.setString("role", data['role'] as String? ?? 'ROLE_USER');
      } catch (e) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Server luôn tạo tài khoản ROLE_USER; tham số [role] được giữ để tương thích nhưng bị bỏ qua.
  static Future<bool> register(String username, String password, String role,
      String fullName, String email, String phoneNumber) async {
    final response = await http.post(
      Uri.parse("${ServerAddress().address}/register"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<int> amountOfAccount() async {
    try {
      final response = await ApiClient.get("/user/get-so-luong-user");
      if (response.statusCode == 200) {
        return int.tryParse(response.body) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<UserModel> getUser(String username) async {
    final response = await ApiClient.get('/user/get-user-info/${Uri.encodeComponent(username)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Không lấy được thông tin user');
    }
  }
}
