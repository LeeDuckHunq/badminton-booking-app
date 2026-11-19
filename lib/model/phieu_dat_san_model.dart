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

  bool get isWalkIn => nguonDat == 'TAI_SAN';

  String get phuongThucLabel => switch (phuongThucThanhToan) {
        'TIEN_MAT' => 'Tiền mặt',
        'CHUYEN_KHOAN' => 'Chuyển khoản',
        'TRA_SAU' => 'Trả sau tại sân',
        _ => 'Tại sân',
      };

  PhieuDatSanModel({
    this.nguonDat = 'APP',
    this.phuongThucThanhToan,
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