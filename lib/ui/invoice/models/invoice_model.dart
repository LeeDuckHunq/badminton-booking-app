// lib/ui/invoice/models/invoice_model.dart

/// Thông tin người dùng hiển thị trên hóa đơn
class InvoiceUserInfo {
  final String maNguoiDung;
  final String hoTen;
  final String soDienThoai;
  final String email;

  const InvoiceUserInfo({
    required this.maNguoiDung,
    required this.hoTen,
    required this.soDienThoai,
    required this.email,
  });
}

/// Thông tin đặt sân
class InvoiceBookingInfo {
  final String maPhieuDat;
  final String tenCumSan;
  final String tenSan;
  final String diaChi;
  final DateTime batDau;
  final DateTime ketThuc;
  final double tongTien;

  const InvoiceBookingInfo({
    required this.maPhieuDat,
    required this.tenCumSan,
    required this.tenSan,
    required this.diaChi,
    required this.batDau,
    required this.ketThuc,
    required this.tongTien,
  });

  double get tongGio => ketThuc.difference(batDau).inMinutes / 60.0;

  String get thoiGian {
    String f(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${f(batDau)} – ${f(ketThuc)}';
  }

  String get ngayDat {
    return '${batDau.day.toString().padLeft(2, '0')}/'
        '${batDau.month.toString().padLeft(2, '0')}/'
        '${batDau.year}';
  }
}

/// Tài khoản ngân hàng nhận thanh toán
class BankAccountModel {
  final String tenNganHang;
  final String soTaiKhoan;
  final String chuTaiKhoan;
  final String? logoUrl;

  const BankAccountModel({
    required this.tenNganHang,
    required this.soTaiKhoan,
    required this.chuTaiKhoan,
    this.logoUrl,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      tenNganHang: json['tenNganHang'] ?? '',
      soTaiKhoan: json['soTaiKhoan'] ?? '',
      chuTaiKhoan: json['chuTaiKhoan'] ?? '',
      logoUrl: json['logoUrl'],
    );
  }
}