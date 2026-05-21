// lib/ui/highlight/models/hot_court_model.dart

import 'package:application/model/cum_san_model.dart';

/// Dữ liệu từ API hot courts ranking
class HotCourtRank {
  final String maCumSan;
  final int soLuongDat;

  const HotCourtRank({
    required this.maCumSan,
    required this.soLuongDat,
  });

  factory HotCourtRank.fromJson(Map<String, dynamic> json) {
    return HotCourtRank(
      maCumSan:    json['maCumSan'] as String,
      soLuongDat: (json['soLuongDat'] as num).toInt(),
    );
  }
}

/// Kết hợp ranking + chi tiết cụm sân
class HotCourtItem {
  final int rank;
  final HotCourtRank rankData;
  final CumSanModel cumSan;
  final String? imageUrl; // ảnh sân, null dùng placeholder gradient

  const HotCourtItem({
    required this.rank,
    required this.rankData,
    required this.cumSan,
    this.imageUrl,
  });
}