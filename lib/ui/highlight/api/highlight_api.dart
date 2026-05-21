// lib/api/highlight_api.dart

import 'dart:convert';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/api/server_address.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/highlight/models/hot_court_model.dart';
import 'package:http/http.dart' as http;

class HighlightApi {
  static const String _baseUrl =
      'https://be-badminton-booking-app-production.up.railway.app';

  // ── 1. Lấy danh sách cụm sân hot (ranking) ─────────────────────────────
  static Future<List<HotCourtRank>> getHotCourts() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerAddress().address}/cumsan/top-10-cum-san'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => HotCourtRank.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── 2. Lấy chi tiết 1 cụm sân theo mã ─────────────────────────────────
  static Future<CumSanModel?> getCumSanInfo(String maCumSan) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cumsan/cum-san-info/$maCumSan'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return CumSanModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  // ── 3. Gộp: lấy ranking rồi fetch song song chi tiết từng sân ──────────
  static Future<List<HotCourtItem>> getHotCourtItems() async {
    final ranks = await getHotCourts();
    final imageFutures = ranks.map((r) => HinhAnhSanApi.getFirstHinhAnhByCumSan(r.maCumSan));
    final images = await Future.wait(imageFutures);
    if (ranks.isEmpty) return [];

    // Fetch chi tiết tất cả cụm sân song song
    final futures = ranks.map((r) => getCumSanInfo(r.maCumSan));
    final results = await Future.wait(futures);

    final items = <HotCourtItem>[];
    for (int i = 0; i < ranks.length; i++) {
      final cumSan = results[i];
      if (cumSan != null) {
        items.add(HotCourtItem(
          rank:     i + 1,
          rankData: ranks[i],
          cumSan:   cumSan,
          imageUrl: images[i],
        ));
      }
    }
    return items;
  }
}