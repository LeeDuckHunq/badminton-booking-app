import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:flutter/cupertino.dart';

class FavoriteApi {
  static Future<Map<String, String>> getFavorites(String username) async {
    try {
      final res = await ApiClient.get('/yeu-thich/${Uri.encodeComponent(username)}');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return {for (var e in data) e['maCumSan'] as String: e['maFav'] as String};
      }
      debugPrint('getFavorites failed: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('getFavorites error: $e');
    }
    return {};
  }

  /// Server luôn thêm cho tài khoản đang đăng nhập (theo JWT).
  static Future<bool> addFavorite(String username, String maCumSan) async {
    final res = await ApiClient.post('/yeu-thich/them', {'maCumSan': maCumSan});
    return res.statusCode == 200;
  }

  static Future<bool> deleteFavorite(String maFav) async {
    final res = await ApiClient.delete('/yeu-thich/xoa/${Uri.encodeComponent(maFav)}');
    return res.statusCode == 200;
  }
}
