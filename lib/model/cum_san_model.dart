// lib/model/cum_san_model.dart
import 'package:flutter/material.dart';

class CumSanModel {
  String maCumSan;
  String tenCumSan;
  String diaChi;
  String moTa;
  String sDT;
  String gioMoCua;
  String gioDongCua;
  String trangThai;

  /// Giá thấp nhất / giờ trong các sân đang hoạt động (null nếu chưa có sân).
  double? giaTu;

  /// Số sân đang hoạt động.
  int soSan;

  /// Điểm đánh giá trung bình 1..5 (null nếu chưa có đánh giá).
  double? diemDanhGia;

  int soDanhGia;

  CumSanModel({
    required this.maCumSan,
    required this.tenCumSan,
    required this.diaChi,
    required this.moTa,
    required this.sDT,
    required this.gioMoCua,
    required this.gioDongCua,
    required this.trangThai,
    this.giaTu,
    this.soSan = 0,
    this.diemDanhGia,
    this.soDanhGia = 0,
  });

  factory CumSanModel.fromJson(Map<String, dynamic> json) {
    return CumSanModel(
      maCumSan: json['maCumSan'] as String? ?? '',
      tenCumSan: json['tenCumSan'] as String? ?? '',
      diaChi: json['diaChi'] as String? ?? '',
      moTa: json['moTa'] as String? ?? '',
      sDT: json['sDT'] as String? ?? '',
      gioMoCua: json['gioMoCua'] as String? ?? '00:00',
      gioDongCua: json['gioDongCua'] as String? ?? '00:00',
      trangThai: json['trangThai'] as String? ?? '',
      giaTu: (json['giaTu'] as num?)?.toDouble(),
      soSan: (json['soSan'] as num?)?.toInt() ?? 0,
      diemDanhGia: (json['diemDanhGia'] as num?)?.toDouble(),
      soDanhGia: (json['soDanhGia'] as num?)?.toInt() ?? 0,
    );
  }

  TimeOfDay parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
