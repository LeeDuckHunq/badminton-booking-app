import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/khuyen_mai_model.dart';

class ClaimVoucherApi {
  /// Voucher còn hiệu lực mà người dùng chưa nhận. Trả về null nếu lỗi mạng.
  static Future<List<KhuyenMaiModel>?> getAvailableVouchers(String username) async {
    try {
      final res = await ApiClient.get('/khuyen-mai/chua-co/${Uri.encodeComponent(username)}');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final now = DateTime.now();
        return data.map((e) => KhuyenMaiModel.fromJson(e)).where((v) => v.ngayKetThuc.isAfter(now)).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Nhận voucher theo mã cho tài khoản đang đăng nhập (theo JWT).
  /// Server luôn trả HTTP 200 kèm thông điệp; chỉ "…thành công" mới là nhận được.
  static Future<({bool ok, String message})> claimVoucher({required String maKhuyenMai}) async {
    try {
      final res = await ApiClient.post('/khuyen-mai/nhan', {'maKhuyenMai': maKhuyenMai.trim()});
      if (res.statusCode == 200) {
        final message = utf8.decode(res.bodyBytes).replaceAll('"', '').trim();
        return (ok: message.toLowerCase().contains('thành công'), message: message);
      }
      return (ok: false, message: ApiClient.errorMessage(res) ?? 'Lấy voucher thất bại');
    } catch (_) {
      return (ok: false, message: 'Không kết nối được máy chủ');
    }
  }
}
