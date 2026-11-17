import 'dart:convert';

import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client dùng chung: tự gắn JWT (Authorization: Bearer ...) và xử lý 401.
class ApiClient {
  ApiClient._();

  /// Được gọi khi server trả về 401 (token hết hạn / tài khoản bị khoá).
  /// main.dart gán callback này để đăng xuất và quay về màn hình đăng nhập.
  static Future<void> Function()? onUnauthorized;

  static bool _handlingUnauthorized = false;

  static Uri uri(String path) => Uri.parse('${ServerAddress().address}$path');

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('jwt_token');
    return (value == null || value.isEmpty) ? null : value;
  }

  static Future<Map<String, String>> headers({bool json = false}) async {
    final result = <String, String>{'Accept': 'application/json'};
    if (json) result['Content-Type'] = 'application/json; charset=UTF-8';
    final jwt = await token();
    if (jwt != null) result['Authorization'] = 'Bearer $jwt';
    return result;
  }

  static Future<http.Response> get(String path) async {
    final res = await http.get(uri(path), headers: await headers());
    await checkUnauthorized(res);
    return res;
  }

  static Future<http.Response> post(String path, Object? body) async {
    final res = await http.post(
      uri(path),
      headers: await headers(json: true),
      body: jsonEncode(body),
    );
    await checkUnauthorized(res);
    return res;
  }

  static Future<http.Response> delete(String path) async {
    final res = await http.delete(uri(path), headers: await headers());
    await checkUnauthorized(res);
    return res;
  }

  static Future<void> checkUnauthorized(http.BaseResponse res) async {
    if (res.statusCode != 401 || _handlingUnauthorized) return;
    final callback = onUnauthorized;
    if (callback == null) return;
    _handlingUnauthorized = true;
    try {
      await callback();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  /// Lấy message lỗi tiếng Việt từ body JSON {"message": "..."} của server.
  static String? errorMessage(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map && data['message'] is String) return data['message'] as String;
    } catch (_) {}
    return null;
  }
}
