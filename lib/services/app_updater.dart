import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:application/api/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thông tin bản phát hành mới nhất trên server.
class AppRelease {
  final String phienBan;
  final int soBuild;
  final int buildToiThieu;
  final List<String> thayDoi;
  final Map<String, String> taiVe;
  final Map<String, int> kichThuoc;
  final DateTime? ngayPhatHanh;
  final bool coBanMoi;
  final bool batBuoc;

  const AppRelease({
    required this.phienBan,
    required this.soBuild,
    this.buildToiThieu = 0,
    this.thayDoi = const [],
    this.taiVe = const {},
    this.kichThuoc = const {},
    this.ngayPhatHanh,
    this.coBanMoi = false,
    this.batBuoc = false,
  });

  factory AppRelease.fromJson(Map<String, dynamic> j) => AppRelease(
        phienBan: j['phienBan'] as String? ?? '',
        soBuild: (j['soBuild'] as num?)?.toInt() ?? 0,
        buildToiThieu: (j['buildToiThieu'] as num?)?.toInt() ?? 0,
        thayDoi: ((j['thayDoi'] as List?) ?? []).map((e) => '$e').toList(),
        taiVe: ((j['taiVe'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v')),
        kichThuoc: ((j['kichThuoc'] as Map?) ?? {}).map((k, v) => MapEntry('$k', (v as num).toInt())),
        ngayPhatHanh: DateTime.tryParse('${j['ngayPhatHanh']}'),
        coBanMoi: j['coBanMoi'] == true,
        batBuoc: j['batBuoc'] == true,
      );
}

/// Thông tin app đang cài trên máy.
class InstalledApp {
  final String versionName;

  /// Số build (versionCode % 1000: bản tách theo CPU cộng thêm 1000/2000/4000 vào versionCode).
  final int build;
  final List<String> abis;
  final String updateDir;

  const InstalledApp({required this.versionName, required this.build, this.abis = const [], this.updateDir = ''});
}

/// Một lần tải APK: theo dõi tiến độ và có thể huỷ.
class UpdateDownload {
  final _controller = StreamController<(int received, int total)>.broadcast();
  http.Client? _client;
  bool _cancelled = false;

  Stream<(int, int)> get progress => _controller.stream;

  void cancel() {
    _cancelled = true;
    _client?.close();
  }

  Future<String> run(String url, String path, {int expectedSize = 0}) async {
    final client = _client = http.Client();
    final file = File(path);
    final temp = File('$path.part');
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw UpdateException('Máy chủ trả về lỗi ${response.statusCode} khi tải bản cập nhật');
      final total = response.contentLength ?? expectedSize;
      final sink = temp.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          if (_cancelled) throw const UpdateException('Đã huỷ tải');
          sink.add(chunk);
          received += chunk.length;
          _controller.add((received, total));
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && received < total) throw const UpdateException('Tải chưa xong, mạng bị gián đoạn. Thử lại nhé');
      if (await file.exists()) await file.delete();
      await temp.rename(path);
      return path;
    } on UpdateException {
      rethrow;
    } catch (e) {
      if (_cancelled) throw const UpdateException('Đã huỷ tải');
      throw const UpdateException('Không tải được bản cập nhật. Kiểm tra kết nối mạng và thử lại');
    } finally {
      client.close();
      if (await temp.exists()) await temp.delete().catchError((_) => temp);
      await _controller.close();
    }
  }
}

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

/// Kiểm tra và cài bản cập nhật APK (chỉ chạy trên Android).
class AppUpdater {
  AppUpdater._();

  static const _channel = MethodChannel('vn.smashzone.app/updater');
  static const _skipKey = 'update_skip_build';
  static const _skipUntilKey = 'update_skip_until';

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<InstalledApp?> installed() async {
    if (!supported) return null;
    try {
      final m = Map<String, dynamic>.from(await _channel.invokeMethod('info') as Map);
      final code = (m['versionCode'] as num).toInt();
      return InstalledApp(
        versionName: m['versionName'] as String? ?? '',
        build: code % 1000,
        abis: ((m['abis'] as List?) ?? []).map((e) => '$e').toList(),
        updateDir: m['updateDir'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('updater info error: $e');
      return null;
    }
  }

  /// Hỏi server bản mới nhất so với build đang cài.
  static Future<AppRelease?> fetch(int build) async {
    try {
      final res = await ApiClient.get('/app/phien-ban?nenTang=android&build=$build');
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (data['phienBan'] == null) return null;
      return AppRelease.fromJson(data);
    } catch (e) {
      debugPrint('updater fetch error: $e');
      return null;
    }
  }

  /// Chọn link tải hợp với CPU của máy (ưu tiên đúng kiến trúc, sau đó bản universal).
  static (String abi, String url)? pickDownload(AppRelease r, List<String> abis) {
    for (final abi in abis) {
      final url = r.taiVe[abi];
      if (url != null) return (abi, url);
    }
    final universal = r.taiVe['universal'];
    if (universal != null) return ('universal', universal);
    if (r.taiVe.isNotEmpty) return (r.taiVe.keys.first, r.taiVe.values.first);
    return null;
  }

  static Future<bool> canInstall() async => (await _channel.invokeMethod('canInstall')) == true;
  static Future<void> openInstallSettings() => _channel.invokeMethod('openInstallSettings');
  static Future<void> install(String path) => _channel.invokeMethod('install', {'path': path});

  /// Người dùng bấm "Để sau": không hỏi lại bản này trong 24 giờ.
  static Future<void> snooze(int build) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_skipKey, build);
    await p.setInt(_skipUntilKey, DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch);
  }

  static Future<bool> isSnoozed(int build) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_skipKey) == build && DateTime.now().millisecondsSinceEpoch < (p.getInt(_skipUntilKey) ?? 0);
  }
}

/// "19,8 MB"
String formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 10 ? 1 : 2).replaceAll('.', ',')} MB';
}
