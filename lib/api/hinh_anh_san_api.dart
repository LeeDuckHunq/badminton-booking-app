// lib/api/hinh_anh_san_api.dart

import 'dart:convert';

import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;

class HinhAnhSanApi {
  static const _fallbackImage =
      'https://c4.wallpaperflare.com/wallpaper/513/95/590/sports-badminton-wallpaper-preview.jpg';

  static Future<String> getHinhAnhSan(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerAddress().address}/anh-san/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return response.body;
      }
    } catch (_) {
      // Lỗi mạng → dùng ảnh fallback
    }

    return _fallbackImage;
  }

  static Future<Map<String, String>> getAllHinhAnhSan() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerAddress().address}/anh-san'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Map sang Map<String, String> an toàn
        return data.map(
              (key, value) => MapEntry(key, value?.toString() ?? _fallbackImage),
        );
      }
    } catch (_) {
      // Lỗi mạng hoặc parse lỗi → trả map rỗng, không crash
    }

    return {};
  }

  static Future<String> getFirstHinhAnhByCumSan(String maCumSan) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerAddress().address}/anh-san/$maCumSan'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first['duongDanHinhAnh'] as String? ?? _fallbackImage;
        }
      }
    } catch (_) {}

    return _fallbackImage;
  }
}