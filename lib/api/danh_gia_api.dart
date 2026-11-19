import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:flutter/foundation.dart';

/// Một đánh giá công khai của cụm sân.
class VenueReview {
  final String tenNguoiDanhGia;
  final int soSao;
  final String? noiDung;
  final String? tenSan;
  final DateTime? ngayTao;
  final bool daSua;
  final String? phanHoi;
  final DateTime? ngayPhanHoi;

  const VenueReview({required this.tenNguoiDanhGia, required this.soSao, this.noiDung, this.tenSan, this.ngayTao, this.daSua = false, this.phanHoi, this.ngayPhanHoi});

  factory VenueReview.fromJson(Map<String, dynamic> j) => VenueReview(
        tenNguoiDanhGia: j['tenNguoiDanhGia'] as String? ?? 'Người chơi SmashZone',
        soSao: (j['soSao'] as num?)?.toInt() ?? 0,
        noiDung: j['noiDung'] as String?,
        tenSan: j['tenSan'] as String?,
        ngayTao: DateTime.tryParse('${j['ngayTao']}'),
        daSua: j['daSua'] == true,
        phanHoi: j['phanHoi'] as String?,
        ngayPhanHoi: DateTime.tryParse('${j['ngayPhanHoi']}'),
      );
}

class VenueReviews {
  final double? diemTrungBinh;
  final int soDanhGia;

  /// Số lượt theo sao: key 5..1.
  final Map<int, int> phanBo;
  final List<VenueReview> reviews;

  const VenueReviews({this.diemTrungBinh, this.soDanhGia = 0, this.phanBo = const {}, this.reviews = const []});

  factory VenueReviews.fromJson(Map<String, dynamic> j) => VenueReviews(
        diemTrungBinh: (j['diemTrungBinh'] as num?)?.toDouble(),
        soDanhGia: (j['soDanhGia'] as num?)?.toInt() ?? 0,
        phanBo: {for (final e in ((j['phanBo'] as Map?) ?? {}).entries) int.parse('${e.key}'): (e.value as num).toInt()},
        reviews: ((j['reviews'] as List?) ?? []).map((e) => VenueReview.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Đánh giá của chính người dùng (theo phiếu đặt).
class MyReview {
  final String maPhieuDat;
  final int soSao;
  final String? noiDung;
  final String? phanHoi;

  const MyReview({required this.maPhieuDat, required this.soSao, this.noiDung, this.phanHoi});

  factory MyReview.fromJson(Map<String, dynamic> j) => MyReview(
        maPhieuDat: j['maPhieuDat'] as String? ?? '',
        soSao: (j['soSao'] as num?)?.toInt() ?? 0,
        noiDung: j['noiDung'] as String?,
        phanHoi: j['phanHoi'] as String?,
      );
}

class DanhGiaApi {
  /// Công khai. Trả về null nếu lỗi mạng.
  static Future<VenueReviews?> venueReviews(String maCumSan) async {
    try {
      final res = await ApiClient.get('/danh-gia/cum-san/${Uri.encodeComponent(maCumSan)}');
      if (res.statusCode == 200) return VenueReviews.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('venueReviews error: $e');
    }
    return null;
  }

  /// Map maPhieuDat → đánh giá của tôi.
  static Future<Map<String, MyReview>> mine() async {
    try {
      final res = await ApiClient.get('/danh-gia/cua-toi');
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).map((e) => MyReview.fromJson(e as Map<String, dynamic>));
        return {for (final r in list) r.maPhieuDat: r};
      }
    } catch (e) {
      debugPrint('myReviews error: $e');
    }
    return {};
  }

  /// Gửi / sửa đánh giá. Trả về null nếu thành công, ngược lại là thông báo lỗi.
  static Future<String?> submit({required String maPhieuDat, required int soSao, String? noiDung}) async {
    try {
      final res = await ApiClient.post('/danh-gia', {'maPhieuDat': maPhieuDat, 'soSao': soSao, 'noiDung': noiDung});
      if (res.statusCode == 200) return null;
      return ApiClient.errorMessage(res) ?? 'Gửi đánh giá thất bại';
    } catch (_) {
      return 'Không kết nối được máy chủ';
    }
  }
}
