import 'dart:convert';
import 'package:application/api/api_client.dart';
import '../model/san_model.dart';

class SanApi {
  static Future<List<SanModel>> getSanTheoCumSan(String maCumSan) async {
    final response = await ApiClient.get('/san/get-san/${Uri.encodeComponent(maCumSan)}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SanModel.fromJson(e)).toList();
    }
    throw Exception('Không lấy được danh sách sân');
  }

  static Future<int> amountOfCourt() async {
    try {
      final response = await ApiClient.get("/san/get-so-luong-san");
      if (response.statusCode == 200) {
        return int.tryParse(response.body) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<SanModel?> getSanInfo(String maSan) async {
    final response = await ApiClient.get("/san/san-info/${Uri.encodeComponent(maSan)}");
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      Map<String, dynamic> json = jsonDecode(response.body);
      return SanModel.fromJson(json);
    }
    return null;
  }
}
