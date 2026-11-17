// lib/api/hoa_don_api.dart
import 'package:application/api/api_client.dart';
import 'package:flutter/foundation.dart';
import '../model/hoa_don_request_model.dart';

class HoaDonResult {
  final bool success;
  final String? message;

  const HoaDonResult(this.success, [this.message]);
}

class HoaDonApi {
  /// Server tự tính tổng tiền và mã hoá đơn; client chỉ gửi phiếu đặt, voucher và URL bill.
  static Future<HoaDonResult> createHoaDon(CreateHoaDonRequest request) async {
    try {
      final response = await ApiClient.post('/hoa-don/tao-hoa-don', request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const HoaDonResult(true);
      }
      debugPrint('BE error ${response.statusCode}: ${response.body}');
      return HoaDonResult(false, ApiClient.errorMessage(response));
    } catch (e) {
      debugPrint('HoaDonApi error: $e');
      return const HoaDonResult(false);
    }
  }
}
