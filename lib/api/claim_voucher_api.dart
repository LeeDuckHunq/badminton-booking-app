import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:http/http.dart' as http;

class ClaimVoucherApi {
  static String get _base => ServerAddress().address;

  static Future<List<KhuyenMaiModel>> getAvailableVouchers(
      String username) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/khuyen-mai/chua-co/$username'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final now = DateTime.now();
        return data
            .map((e) => KhuyenMaiModel.fromJson(e))
            .where((v) => v.ngayKetThuc.isAfter(now))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> claimVoucher({
    required String username,
    required String maKhuyenMai,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/khuyen-mai/nhan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'maKhuyenMai': maKhuyenMai,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}