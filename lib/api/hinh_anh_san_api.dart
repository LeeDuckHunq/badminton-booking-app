// lib/api/hinh_anh_san_api.dart
import 'dart:convert';
import 'package:application/api/api_client.dart';

class HinhAnhSanApi {
  static const _fallbackImage =
      'https://c4.wallpaperflare.com/wallpaper/513/95/590/sports-badminton-wallpaper-preview.jpg';

  /// Map maCumSan → ảnh đại diện.
  static Future<Map<String, String>> getAllHinhAnhSan() async {
    try {
      final response = await ApiClient.get('/anh-san');
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map(
          (key, value) => MapEntry(key, value?.toString() ?? _fallbackImage),
        );
      }
    } catch (_) {
      // Lỗi mạng hoặc parse lỗi → trả map rỗng, không crash
    }
    return {};
  }

  /// Ảnh đầu tiên của cụm sân. Server trả về danh sách URL (List<String>).
  static Future<String> getFirstHinhAnhByCumSan(String maCumSan) async {
    try {
      final response = await ApiClient.get('/anh-san/${Uri.encodeComponent(maCumSan)}');
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final url = item is String
              ? item
              : (item is Map ? item['duongDanHinhAnh'] as String? : null);
          if (url != null && url.isNotEmpty) return url;
        }
      }
    } catch (_) {}
    return _fallbackImage;
  }
}
