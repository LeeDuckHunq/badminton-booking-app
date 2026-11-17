import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:flutter/foundation.dart';

class KhuyenMaiApi {
  /// Voucher user đang có, còn hạn và chưa sử dụng.
  static Future<List<KhuyenMaiModel>> getKhuyenMaiTheoUser(String username) async {
    try {
      final response = await ApiClient.get('/khuyen-mai/get-khuyen-mai/${Uri.encodeComponent(username)}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => KhuyenMaiModel.fromJson(e)).toList();
      }
      throw Exception("Lỗi API: ${response.statusCode}");
    } catch (e) {
      debugPrint("Lỗi getKhuyenMaiTheoUser: $e");
      return [];
    }
  }
}
