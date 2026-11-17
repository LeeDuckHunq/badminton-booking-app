import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/khuyen_mai_model.dart';

class ClaimVoucherApi {
  static Future<List<KhuyenMaiModel>> getAvailableVouchers(String username) async {
    try {
      final res = await ApiClient.get('/khuyen-mai/chua-co/${Uri.encodeComponent(username)}');
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

  /// Server luôn nhận voucher cho tài khoản đang đăng nhập (theo JWT).
  static Future<bool> claimVoucher({
    required String username,
    required String maKhuyenMai,
  }) async {
    try {
      final res = await ApiClient.post('/khuyen-mai/nhan', {'maKhuyenMai': maKhuyenMai});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
