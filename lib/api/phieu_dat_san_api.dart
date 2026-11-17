import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/create_phieu_dat_model.dart';
import 'package:flutter/foundation.dart';
import '../model/phieu_dat_san_model.dart';

class PhieuDatSanApi {
  /// Lịch đặt công khai trong ngày (không kèm thông tin người đặt).
  static Future<List<PhieuDatSanModel>> getPhieuDatTheoNgay(DateTime ngay) async {
    final formattedDate = "${ngay.year}"
        "-${ngay.month.toString().padLeft(2, '0')}"
        "-${ngay.day.toString().padLeft(2, '0')}";

    final response = await ApiClient.get('/phieu-dat-san/theo-ngay?ngay=$formattedDate');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PhieuDatSanModel.fromJson(e)).toList();
    }
    throw Exception('Không lấy được lịch đặt sân');
  }

  /// Tạo phiếu đặt. Server lấy người đặt từ JWT.
  /// Trả về mã phiếu khi thành công, hoặc thông báo lỗi từ server.
  static Future<({String? maPhieuDat, String? message})> createPhieuDat(CreatePhieuDatModel request) async {
    try {
      final response = await ApiClient.post('/phieu-dat-san/create', request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (maPhieuDat: data['maPhieuDat'] as String?, message: null);
      }
      debugPrint('createPhieuDat failed ${response.statusCode}: ${response.body}');
      return (maPhieuDat: null, message: ApiClient.errorMessage(response));
    } catch (e) {
      debugPrint('createPhieuDat error: $e');
      return (maPhieuDat: null, message: 'Không kết nối được máy chủ');
    }
  }

  static Future<List<PhieuDatSanModel>> getPhieuDatSanTheoUser(String username) async {
    final response = await ApiClient.get('/phieu-dat-san/get-theo-user/${Uri.encodeComponent(username)}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PhieuDatSanModel.fromJson(e)).toList();
    }
    throw Exception('Không lấy được lịch đặt sân');
  }

  static Future<bool> deletePhieuDat(String maPhieuDat) async {
    final response = await ApiClient.delete(
      '/phieu-dat-san/delete-phieu-dat/${Uri.encodeComponent(maPhieuDat)}',
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw Exception(ApiClient.errorMessage(response) ??
        'Xóa phiếu đặt thất bại (${response.statusCode})');
  }
}
