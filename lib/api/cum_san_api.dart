// lib/api/cum_san_api.dart

import 'dart:convert';

import 'package:application/api/server_address.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:http/http.dart' as http;

class CumSanApi {
  static Future<List<CumSanModel>?> getCumSan(int amount) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerAddress().address}/cumsan/$amount'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        // FIX: Map từng item sang CumSanModel thay vì trả List<dynamic> thô
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
    final response = await http.get(
        Uri.parse('${ServerAddress().address}/cumsan/cum-san-info/${maCumSan}'),
        headers: ({'Accept': 'application/json'})
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      return CumSanModel.fromJson(json);
    }

    return null;
  }
}