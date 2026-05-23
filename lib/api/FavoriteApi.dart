import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FavoriteApi {

  static Future<Map<String, String>> getFavorites(String username) async {
    final res = await http.get(Uri.parse('${ServerAddress().address}/yeu-thich/$username'));
    debugPrint('getFavorites response: ${res.body}');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return { for (var e in data) e['maCumSan'] as String: e['maFav'] as String };
    }
    return {};
  }

  static Future<bool> addFavorite(String username, String maCumSan) async {
    final res = await http.post(
      Uri.parse('${ServerAddress().address}/yeu-thich/them'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'maFav': '',
        'maNguoiDung': username,
        'maCumSan': maCumSan,
      }),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteFavorite(String maFav) async {
    final res = await http.delete(Uri.parse('${ServerAddress().address}/yeu-thich/xoa/$maFav'));
    return res.statusCode == 200;
  }
}