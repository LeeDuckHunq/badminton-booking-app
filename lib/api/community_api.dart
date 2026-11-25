import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:http/http.dart' as http;

/// Lỗi trả về từ API cộng đồng (thông báo tiếng Việt của server).
class CommunityException implements Exception {
  final String message;
  final int status;
  const CommunityException(this.message, [this.status = 0]);

  @override
  String toString() => message;
}

DateTime _date(dynamic v) => DateTime.tryParse('$v') ?? DateTime.now();
int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

class PersonRef {
  final String username;
  final String ten;
  const PersonRef(this.username, this.ten);
  factory PersonRef.fromJson(Map<String, dynamic>? j) => PersonRef(j?['username'] as String? ?? '', j?['ten'] as String? ?? '');
}

/// Trạng thái của tôi trong trận.
class MyMatchState {
  final String? trangThai;
  final String? thanhToan;
  final int soTien;
  final bool laChuTran;
  final bool laThanhVienNhom;
  const MyMatchState({this.trangThai, this.thanhToan, this.soTien = 0, this.laChuTran = false, this.laThanhVienNhom = false});
  factory MyMatchState.fromJson(Map<String, dynamic> j) => MyMatchState(
        trangThai: j['trangThai'] as String?,
        thanhToan: j['thanhToan'] as String?,
        soTien: _int(j['soTien']),
        laChuTran: j['laChuTran'] == true,
        laThanhVienNhom: j['laThanhVienNhom'] == true,
      );
}

class MatchPlayer {
  final String username;
  final String ten;
  final String trangThai;
  final bool laChuTran;
  final String? trinhDo;
  final String? thanhToan;
  final int soTien;
  final String? billUrl;
  final String? loiNhan;
  final int? soTranDaChoi;
  const MatchPlayer({required this.username, required this.ten, required this.trangThai, this.laChuTran = false, this.trinhDo, this.thanhToan, this.soTien = 0, this.billUrl, this.loiNhan, this.soTranDaChoi});
  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
        username: j['username'] as String? ?? '',
        ten: j['ten'] as String? ?? '',
        trangThai: j['trangThai'] as String? ?? '',
        laChuTran: j['laChuTran'] == true,
        trinhDo: j['trinhDo'] as String?,
        thanhToan: j['thanhToan'] as String?,
        soTien: _int(j['soTien']),
        billUrl: j['billUrl'] as String?,
        loiNhan: j['loiNhan'] as String?,
        soTranDaChoi: (j['soTranDaChoi'] as num?)?.toInt(),
      );
}

class BankInfo {
  final String nganHang;
  final String soTaiKhoan;
  final String? chuTaiKhoan;
  const BankInfo(this.nganHang, this.soTaiKhoan, this.chuTaiKhoan);
}

class MatchInfo {
  final String maTran;
  final String tieuDe;
  final String kieuChoi;
  final String? maNhom;
  final String? tenNhom;
  final int mauNhom;
  final String maCumSan;
  final String tenCumSan;
  final String? diaChi;
  final String tenSan;
  final DateTime batDau;
  final DateTime ketThuc;
  final PersonRef chuTran;
  final int soNguoiToiDa;
  final int soDaThamGia;
  final int soChoDuyet;
  final String? trinhDoTu;
  final String? trinhDoDen;
  final int chiPhiMoiNguoi;
  final bool congKhai;
  final String trangThai;
  final MyMatchState? toi;
  // Chỉ có ở màn chi tiết
  final String? ghiChu;
  final BankInfo? nhanTien;
  final List<MatchPlayer> thanhVien;
  final int? daThu;
  final int? canThu;
  final int? tienSan;

  const MatchInfo({
    required this.maTran, required this.tieuDe, required this.kieuChoi, this.maNhom, this.tenNhom, this.mauNhom = 0,
    required this.maCumSan, required this.tenCumSan, this.diaChi, required this.tenSan, required this.batDau, required this.ketThuc,
    required this.chuTran, required this.soNguoiToiDa, required this.soDaThamGia, this.soChoDuyet = 0, this.trinhDoTu, this.trinhDoDen,
    required this.chiPhiMoiNguoi, required this.congKhai, required this.trangThai, this.toi, this.ghiChu, this.nhanTien,
    this.thanhVien = const [], this.daThu, this.canThu, this.tienSan,
  });

  bool get upcoming => trangThai == 'MO' || trangThai == 'DU_NGUOI';
  bool get finished => trangThai == 'DA_HUY' || trangThai == 'DA_KET_THUC';

  factory MatchInfo.fromJson(Map<String, dynamic> j) {
    final bank = j['nhanTien'] as Map<String, dynamic>?;
    return MatchInfo(
      maTran: j['maTran'] as String? ?? '',
      tieuDe: j['tieuDe'] as String? ?? '',
      kieuChoi: j['kieuChoi'] as String? ?? 'DOI',
      maNhom: j['maNhom'] as String?,
      tenNhom: j['tenNhom'] as String?,
      mauNhom: _int(j['mauNhom']),
      maCumSan: j['maCumSan'] as String? ?? '',
      tenCumSan: j['tenCumSan'] as String? ?? 'Cụm sân',
      diaChi: j['diaChi'] as String?,
      tenSan: j['tenSan'] as String? ?? '',
      batDau: _date(j['batDau']),
      ketThuc: _date(j['ketThuc']),
      chuTran: PersonRef.fromJson(j['chuTran'] as Map<String, dynamic>?),
      soNguoiToiDa: _int(j['soNguoiToiDa']),
      soDaThamGia: _int(j['soDaThamGia']),
      soChoDuyet: _int(j['soChoDuyet']),
      trinhDoTu: j['trinhDoTu'] as String?,
      trinhDoDen: j['trinhDoDen'] as String?,
      chiPhiMoiNguoi: _int(j['chiPhiMoiNguoi']),
      congKhai: j['congKhai'] == true,
      trangThai: j['trangThai'] as String? ?? 'MO',
      toi: j['toi'] == null ? null : MyMatchState.fromJson(j['toi'] as Map<String, dynamic>),
      ghiChu: j['ghiChu'] as String?,
      nhanTien: bank == null || bank['soTaiKhoan'] == null ? null : BankInfo(bank['nganHang'] as String? ?? '', bank['soTaiKhoan'] as String, bank['chuTaiKhoan'] as String?),
      thanhVien: ((j['thanhVien'] as List?) ?? []).map((e) => MatchPlayer.fromJson(e as Map<String, dynamic>)).toList(),
      daThu: (j['daThu'] as num?)?.toInt(),
      canThu: (j['canThu'] as num?)?.toInt(),
      tienSan: (j['tienSan'] as num?)?.toInt(),
    );
  }
}

/// Lượt đặt sân có thể mở trận.
class MatchBooking {
  final String maPhieuDat;
  final DateTime batDau;
  final DateTime ketThuc;
  final int tongTien;
  final String trangThai;
  final String? maCumSan;
  final String tenCumSan;
  final String tenSan;
  const MatchBooking({required this.maPhieuDat, required this.batDau, required this.ketThuc, required this.tongTien, required this.trangThai, this.maCumSan, required this.tenCumSan, required this.tenSan});
  factory MatchBooking.fromJson(Map<String, dynamic> j) => MatchBooking(
        maPhieuDat: j['maPhieuDat'] as String? ?? '',
        batDau: _date(j['batDau']),
        ketThuc: _date(j['ketThuc']),
        tongTien: _int(j['tongTien']),
        trangThai: j['trangThai'] as String? ?? '',
        maCumSan: j['maCumSan'] as String?,
        tenCumSan: j['tenCumSan'] as String? ?? 'Cụm sân',
        tenSan: j['tenSan'] as String? ?? '',
      );
}

class GroupMember {
  final String username;
  final String ten;
  final String vaiTro;
  final String? loiNhan;
  final DateTime? ngayThamGia;
  const GroupMember({required this.username, required this.ten, required this.vaiTro, this.loiNhan, this.ngayThamGia});
  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        username: j['username'] as String? ?? '',
        ten: j['ten'] as String? ?? '',
        vaiTro: j['vaiTro'] as String? ?? 'THANH_VIEN',
        loiNhan: j['loiNhan'] as String?,
        ngayThamGia: DateTime.tryParse('${j['ngayThamGia']}'),
      );
}

class GroupInfo {
  final String maNhom;
  final String tenNhom;
  final String? moTa;
  final String? khuVuc;
  final String? trinhDo;
  final bool congKhai;
  final int mau;
  final bool khoa;
  final int soThanhVien;
  final PersonRef? truongNhom;
  final List<String> thanhVienTieuBieu;
  final String? vaiTro;
  final String? trangThaiCuaToi;
  final String? tinNhanCuoi;
  final DateTime? thoiGianTinNhanCuoi;
  final String? maMoi;
  final List<GroupMember> thanhVien;
  final List<GroupMember> yeuCau;

  const GroupInfo({
    required this.maNhom, required this.tenNhom, this.moTa, this.khuVuc, this.trinhDo, this.congKhai = true, this.mau = 0, this.khoa = false,
    this.soThanhVien = 0, this.truongNhom, this.thanhVienTieuBieu = const [], this.vaiTro, this.trangThaiCuaToi, this.tinNhanCuoi,
    this.thoiGianTinNhanCuoi, this.maMoi, this.thanhVien = const [], this.yeuCau = const [],
  });

  bool get isMember => trangThaiCuaToi == 'THANH_VIEN';
  bool get isPending => trangThaiCuaToi == 'CHO_DUYET';
  bool get isLeader => isMember && (vaiTro == 'TRUONG_NHOM' || vaiTro == 'PHO_NHOM');
  bool get isOwner => isMember && vaiTro == 'TRUONG_NHOM';

  factory GroupInfo.fromJson(Map<String, dynamic> j) {
    final toi = j['toi'] as Map<String, dynamic>?;
    return GroupInfo(
      maNhom: j['maNhom'] as String? ?? '',
      tenNhom: j['tenNhom'] as String? ?? 'Nhóm',
      moTa: j['moTa'] as String?,
      khuVuc: j['khuVuc'] as String?,
      trinhDo: j['trinhDo'] as String?,
      congKhai: j['congKhai'] != false,
      mau: _int(j['mau']),
      khoa: j['khoa'] == true,
      soThanhVien: _int(j['soThanhVien']),
      truongNhom: j['truongNhom'] == null ? null : PersonRef.fromJson(j['truongNhom'] as Map<String, dynamic>),
      thanhVienTieuBieu: ((j['thanhVienTieuBieu'] as List?) ?? []).map((e) => '$e').toList(),
      vaiTro: toi?['vaiTro'] as String?,
      trangThaiCuaToi: toi?['trangThai'] as String?,
      tinNhanCuoi: j['tinNhanCuoi'] as String?,
      thoiGianTinNhanCuoi: DateTime.tryParse('${j['thoiGianTinNhanCuoi']}'),
      maMoi: j['maMoi'] as String?,
      thanhVien: ((j['thanhVien'] as List?) ?? []).map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList(),
      yeuCau: ((j['yeuCau'] as List?) ?? []).map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class GroupMessage {
  final String id;
  final String? username;
  final String? ten;
  final String noiDung;
  final DateTime thoiGian;
  final bool heThong;
  const GroupMessage({required this.id, this.username, this.ten, required this.noiDung, required this.thoiGian, this.heThong = false});
  factory GroupMessage.fromJson(Map<String, dynamic> j) => GroupMessage(
        id: j['maTinNhan'] as String? ?? '',
        username: j['usernameNguoiGui'] as String?,
        ten: j['tenNguoiGui'] as String?,
        noiDung: j['noiDung'] as String? ?? '',
        thoiGian: _date(j['thoiGianGui']),
        heThong: j['heThong'] == true,
      );
}

/// API ghép trận + hội nhóm. Lỗi ném [CommunityException] với thông báo của server.
class CommunityApi {
  static dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) return text.isEmpty ? null : jsonDecode(text);
    throw CommunityException(ApiClient.errorMessage(res) ?? 'Có lỗi xảy ra, vui lòng thử lại.', res.statusCode);
  }

  static Future<dynamic> _get(String path) async {
    try {
      return _decode(await ApiClient.get(path));
    } on CommunityException {
      rethrow;
    } catch (_) {
      throw const CommunityException('Không kết nối được máy chủ');
    }
  }

  static Future<dynamic> _send(String method, String path, [Object? body]) async {
    try {
      final res = switch (method) {
        'PUT' => await ApiClient.put(path, body ?? {}),
        'DELETE' => await ApiClient.delete(path),
        _ => await ApiClient.post(path, body ?? {}),
      };
      return _decode(res);
    } on CommunityException {
      rethrow;
    } catch (_) {
      throw const CommunityException('Không kết nối được máy chủ');
    }
  }

  static String _q(Map<String, String?> params) {
    final entries = params.entries.where((e) => e.value != null && e.value!.isNotEmpty);
    if (entries.isEmpty) return '';
    return '?${entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value!)}').join('&')}';
  }

  static String _e(String s) => Uri.encodeComponent(s);
  static List<MatchInfo> _matches(dynamic data) => ((data as List?) ?? []).map((e) => MatchInfo.fromJson(e as Map<String, dynamic>)).toList();
  static List<GroupInfo> _groups(dynamic data) => ((data as List?) ?? []).map((e) => GroupInfo.fromJson(e as Map<String, dynamic>)).toList();

  // ── Trận ────────────────────────────────────────────────────────────────
  static Future<List<MatchInfo>> search({String? ngay, String? trinhDo, String? kieuChoi, String? maCumSan, bool conCho = false}) async =>
      _matches(await _get('/tran/tim-kiem${_q({'ngay': ngay, 'trinhDo': trinhDo, 'kieuChoi': kieuChoi, 'maCumSan': maCumSan, 'conCho': conCho ? 'true' : null})}'));
  static Future<List<MatchInfo>> myMatches() async => _matches(await _get('/tran/cua-toi'));
  static Future<MatchInfo> match(String id) async => MatchInfo.fromJson(await _get('/tran/${_e(id)}'));
  static Future<List<MatchBooking>> bookings() async => ((await _get('/tran/phieu-dat-kha-dung') as List?) ?? []).map((e) => MatchBooking.fromJson(e as Map<String, dynamic>)).toList();
  static Future<MatchInfo> create(Map<String, dynamic> body) async => MatchInfo.fromJson(await _send('POST', '/tran', body));
  static Future<MatchInfo> update(String id, Map<String, dynamic> body) async => MatchInfo.fromJson(await _send('PUT', '/tran/${_e(id)}', body));
  static Future<MatchInfo> cancel(String id) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/huy'));
  static Future<MatchInfo> join(String id, {String? trinhDo, String? loiNhan}) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/tham-gia', {'trinhDo': trinhDo, 'loiNhan': loiNhan}));
  static Future<MatchInfo> leave(String id) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/roi'));
  static Future<MatchInfo> review(String id, String username, bool accept) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/duyet/${_e(username)}', {'dongY': accept}));
  static Future<MatchInfo> kick(String id, String username) async => MatchInfo.fromJson(await _send('DELETE', '/tran/${_e(id)}/nguoi-choi/${_e(username)}'));
  static Future<MatchInfo> pay(String id, String? billUrl) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/thanh-toan', {'billUrl': billUrl}));
  static Future<MatchInfo> confirmPaid(String id, String username, bool paid) async => MatchInfo.fromJson(await _send('POST', '/tran/${_e(id)}/thanh-toan/${_e(username)}', {'daTra': paid}));

  // ── Nhóm ────────────────────────────────────────────────────────────────
  static Future<List<GroupInfo>> myGroups() async => _groups(await _get('/nhom/cua-toi'));
  static Future<List<GroupInfo>> discover({String? q, String? trinhDo}) async => _groups(await _get('/nhom/kham-pha${_q({'q': q, 'trinhDo': trinhDo})}'));
  static Future<GroupInfo> group(String id) async => GroupInfo.fromJson(await _get('/nhom/${_e(id)}'));
  static Future<GroupInfo> createGroup(Map<String, dynamic> body) async => GroupInfo.fromJson(await _send('POST', '/nhom', body));
  static Future<GroupInfo> updateGroup(String id, Map<String, dynamic> body) async => GroupInfo.fromJson(await _send('PUT', '/nhom/${_e(id)}', body));
  static Future<void> disband(String id) => _send('DELETE', '/nhom/${_e(id)}');
  static Future<GroupInfo> joinGroup(String id, {String? maMoi, String? loiNhan}) async => GroupInfo.fromJson(await _send('POST', '/nhom/${_e(id)}/tham-gia', {'maMoi': maMoi, 'loiNhan': loiNhan}));
  static Future<GroupInfo> joinByCode(String code) async => GroupInfo.fromJson(await _send('POST', '/nhom/tham-gia-bang-ma', {'maMoi': code}));
  static Future<void> cancelRequest(String id) => _send('DELETE', '/nhom/${_e(id)}/yeu-cau');
  static Future<void> leaveGroup(String id) => _send('POST', '/nhom/${_e(id)}/roi');
  static Future<GroupInfo> reviewMember(String id, String username, bool accept) async => GroupInfo.fromJson(await _send('POST', '/nhom/${_e(id)}/duyet/${_e(username)}', {'dongY': accept}));
  static Future<GroupInfo> setRole(String id, String username, String role) async => GroupInfo.fromJson(await _send('POST', '/nhom/${_e(id)}/vai-tro/${_e(username)}', {'vaiTro': role}));
  static Future<GroupInfo> kickMember(String id, String username) async => GroupInfo.fromJson(await _send('DELETE', '/nhom/${_e(id)}/thanh-vien/${_e(username)}'));
  static Future<GroupInfo> newCode(String id) async => GroupInfo.fromJson(await _send('POST', '/nhom/${_e(id)}/ma-moi'));
  static Future<List<GroupMessage>> messages(String id) async => ((await _get('/nhom/${_e(id)}/tin-nhan') as List?) ?? []).map((e) => GroupMessage.fromJson(e as Map<String, dynamic>)).toList();
  static Future<GroupMessage> send(String id, String text) async => GroupMessage.fromJson(await _send('POST', '/nhom/${_e(id)}/tin-nhan', {'noiDung': text}));
  static Future<List<MatchInfo>> groupMatches(String id) async => _matches(await _get('/nhom/${_e(id)}/tran'));
}
