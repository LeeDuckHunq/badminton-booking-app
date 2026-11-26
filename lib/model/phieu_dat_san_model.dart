import 'package:application/utils/date_utils.dart';

class PhieuDatSanModel {
  final String maPhieuDat;
  final String maNguoiDung;
  final String maSan;
  final DateTime batDau;
  final DateTime ketThuc;
  final double tongTien;
  final String? maKhuyenMai;
  final DateTime ngayLap;
  final String trangThai;

  /// APP (khách tự đặt) hoặc TAI_SAN (chủ sân đặt hộ).
  final String nguonDat;

  /// Đơn đặt hộ: TIEN_MAT, CHUYEN_KHOAN, TRA_SAU.
  final String? phuongThucThanhToan;

  /// Khách xin huỷ: CHO_XU_LY, DONG_Y, TU_CHOI (null = chưa xin).
  final String? yeuCauHuy;
  final String? lyDoHuy;
  final String? phanHoiHuy;

  /// Chủ sân đổi sân: sân cũ + lý do.
  final String? maSanCu;
  final String? lyDoDoiSan;

  bool get isWalkIn => nguonDat == 'TAI_SAN';
  bool get cancelPending => yeuCauHuy == 'CHO_XU_LY' && trangThai != 'DA_HUY';

  /// Khách xin huỷ được: đơn đã xác nhận (khách tự đặt), còn hơn 30 phút tới giờ chơi, chưa có yêu cầu đang chờ.
  bool get canRequestCancel =>
      trangThai == 'DA_XAC_NHAN' && !isWalkIn && !cancelPending && batDau.difference(DateTime.now()).inMinutes > 30;

  String get phuongThucLabel => switch (phuongThucThanhToan) {
        'TIEN_MAT' => 'Tiền mặt',
        'CHUYEN_KHOAN' => 'Chuyển khoản',
        'TRA_SAU' => 'Trả sau tại sân',
        _ => 'Tại sân',
      };

  PhieuDatSanModel({
    this.nguonDat = 'APP',
    this.phuongThucThanhToan,
    this.yeuCauHuy,
    this.lyDoHuy,
    this.phanHoiHuy,
    this.maSanCu,
    this.lyDoDoiSan,
    required this.maPhieuDat,
    required this.maNguoiDung,
    required this.maSan,
    required this.batDau,
    required this.ketThuc,
    required this.tongTien,
    this.maKhuyenMai,
    required this.ngayLap,
    required this.trangThai,
  });

  factory PhieuDatSanModel.fromJson(Map<String, dynamic> json) {
    return PhieuDatSanModel(
      maPhieuDat: json['maPhieuDat'] as String? ?? '',
      // Lịch công khai (/theo-ngay) không trả về người đặt và ngày lập.
      maNguoiDung: json['maNguoiDung'] as String? ?? '',
      maSan: json['maSan'] as String? ?? '',
      batDau:  DateTime.parse(json['batDau']).toLocal(),
      ketThuc: DateTime.parse(json['ketThuc']).toLocal(),
      tongTien: (json['tongTien'] as num?)?.toDouble() ?? 0,
      maKhuyenMai: json['maKhuyenMai'],
      ngayLap: json['ngayLap'] == null
          ? DateTime.parse(json['batDau']).toLocal()
          : DateTime.parse(json['ngayLap']).toLocal(),
      trangThai: json['trangThai'] ?? 'CHO_XAC_NHAN',
      nguonDat: json['nguonDat'] as String? ?? 'APP',
      phuongThucThanhToan: json['phuongThucThanhToan'] as String?,
      yeuCauHuy: json['yeuCauHuy'] as String?,
      lyDoHuy: json['lyDoHuy'] as String?,
      phanHoiHuy: json['phanHoiHuy'] as String?,
      maSanCu: json['maSanCu'] as String?,
      lyDoDoiSan: json['lyDoDoiSan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maPhieuDat': maPhieuDat,
      'maNguoiDung': maNguoiDung,
      'maSan': maSan,
      'batDau':  toLocalIso(batDau),
      'ketThuc': toLocalIso(ketThuc),
      'tongTien': tongTien,
      'maKhuyenMai': maKhuyenMai,
      'ngayLap': toLocalIso(ngayLap),
      'trangThai': trangThai,
    };
  }
}