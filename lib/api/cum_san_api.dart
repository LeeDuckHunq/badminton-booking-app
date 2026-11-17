// lib/api/cum_san_api.dart
import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/cum_san_model.dart';

class CumSanApi {
  static Future<List<CumSanModel>?> getCumSan(int amount) async {
    try {
      final response = await ApiClient.get('/cumsan/$amount');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((item) => CumSanModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      // Lỗi mạng, timeout, parse lỗi... đều trả null thay vì crash
      return null;
    }
  }

  static Future<CumSanModel?> getCumSanInfo(String maCumSan) async {
    final response = await ApiClient.get('/cumsan/cum-san-info/${Uri.encodeComponent(maCumSan)}');
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return CumSanModel.fromJson(json);
    }
    return null;
  }
}
