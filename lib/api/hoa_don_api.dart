// lib/api/hoa_don_api.dart

import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;
import '../model/hoa_don_request_model.dart';

class HoaDonApi {

  static Future<bool> createHoaDon(CreateHoaDonRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerAddress().address}/hoa-don/tao-hoa-don'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('BE error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('HoaDonApi error: $e');
      return false;
    }
  }
}