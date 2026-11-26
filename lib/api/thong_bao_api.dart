import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:flutter/material.dart';

/// Một thông báo của tài khoản đang đăng nhập.
class ThongBao {
  final String maThongBao;
  final String loai;
  final String tieuDe;
  final String noiDung;
  final String? doiTuong;
  final String? maDoiTuong;
  final String? nguoiGui;
  final bool daDoc;
  final DateTime thoiGian;

  const ThongBao({
    required this.maThongBao,
    required this.loai,
    required this.tieuDe,
    required this.noiDung,
    this.doiTuong,
    this.maDoiTuong,
    this.nguoiGui,
    this.daDoc = false,
    required this.thoiGian,
  });

  factory ThongBao.fromJson(Map<String, dynamic> j) => ThongBao(
        maThongBao: j['maThongBao'] as String? ?? '',
        loai: j['loai'] as String? ?? '',
        tieuDe: j['tieuDe'] as String? ?? '',
        noiDung: j['noiDung'] as String? ?? '',
        doiTuong: j['doiTuong'] as String?,
        maDoiTuong: j['maDoiTuong'] as String?,
        nguoiGui: j['nguoiGui'] as String?,
        daDoc: j['daDoc'] == true,
        thoiGian: DateTime.tryParse('${j['thoiGian']}')?.toLocal() ?? DateTime.now(),
      );

  ThongBao read() => ThongBao(maThongBao: maThongBao, loai: loai, tieuDe: tieuDe, noiDung: noiDung, doiTuong: doiTuong, maDoiTuong: maDoiTuong, nguoiGui: nguoiGui, daDoc: true, thoiGian: thoiGian);

  /// (biểu tượng, màu chữ, màu nền, nhóm)
  (IconData, Color, Color, String) get style => switch (loai) {
        'DAT_SAN_XAC_NHAN' => (Icons.event_available_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Đặt sân'),
        'DAT_SAN_HUY' => (Icons.event_busy_rounded, const Color(0xFFB91C1C), const Color(0xFFFEE2E2), 'Đặt sân'),
        'DAT_SAN_HOAN_THANH' => (Icons.star_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7), 'Đặt sân'),
        'DAT_SAN_DOI_SAN' || 'TRAN_DOI_SAN' => (Icons.swap_horiz_rounded, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), 'Đặt sân'),
        'DAT_HO' => (Icons.storefront_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Đặt sân'),
        'DON_MOI' => (Icons.receipt_long_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7), 'Đặt sân'),
        'YEU_CAU_HUY' => (Icons.event_busy_rounded, const Color(0xFFB91C1C), const Color(0xFFFEE2E2), 'Đặt sân'),
        'HUY_BI_TU_CHOI' => (Icons.gpp_maybe_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7), 'Đặt sân'),
        'TIN_NHAN' => (Icons.chat_bubble_rounded, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), 'Tin nhắn'),
        'TRAN_XIN_VAO' => (Icons.person_add_alt_1_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Cộng đồng'),
        'TRAN_DUOC_DUYET' || 'TRAN_LEN_DANH_SACH' => (Icons.how_to_reg_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Cộng đồng'),
        'TRAN_TU_CHOI' => (Icons.person_off_rounded, const Color(0xFF64748B), const Color(0xFFF1F5F9), 'Cộng đồng'),
        'TRAN_HUY' => (Icons.block_rounded, const Color(0xFFB91C1C), const Color(0xFFFEE2E2), 'Cộng đồng'),
        'TRAN_DA_CHUYEN_TIEN' => (Icons.account_balance_wallet_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7), 'Cộng đồng'),
        'DANH_GIA_PHAN_HOI' => (Icons.rate_review_rounded, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), 'Đánh giá'),
        'KET_BAN_LOI_MOI' => (Icons.person_add_alt_1_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Tin nhắn'),
        'KET_BAN_DONG_Y' => (Icons.how_to_reg_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Tin nhắn'),
        _ => (Icons.notifications_rounded, const Color(0xFF64748B), const Color(0xFFF1F5F9), 'Khác'),
      };
}

class ThongBaoApi {
  /// 60 thông báo mới nhất + số chưa đọc. Null nếu lỗi mạng.
  static Future<({List<ThongBao> items, int unread})?> list() async {
    try {
      final res = await ApiClient.get('/thong-bao');
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? []).map((e) => ThongBao.fromJson(e as Map<String, dynamic>)).toList();
      return (items: items, unread: (data['chuaDoc'] as num?)?.toInt() ?? 0);
    } catch (_) {
      return null;
    }
  }

  /// Thông báo chưa hiện lên điện thoại (gọi xong máy chủ coi như đã gửi).
  static Future<List<ThongBao>> takePending() async {
    try {
      final res = await ApiClient.get('/thong-bao/chua-gui');
      if (res.statusCode != 200) return [];
      return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) => ThongBao.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> markRead(String id) async {
    try {
      await ApiClient.post('/thong-bao/${Uri.encodeComponent(id)}/da-doc', null);
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      await ApiClient.post('/thong-bao/da-doc-het', null);
    } catch (_) {}
  }
}
