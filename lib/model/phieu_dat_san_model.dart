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

  PhieuDatSanModel({
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

  factory PhieuDatSanModel.fromJson(
      Map<String, dynamic> json) {
    return PhieuDatSanModel(
      maPhieuDat: json['maPhieuDat'],
      maNguoiDung: json['maNguoiDung'],
      maSan: json['maSan'],
      batDau: DateTime.parse(
        json['batDau'],
      ),
      ketThuc: DateTime.parse(
        json['ketThuc'],
      ),
      tongTien:
      (json['tongTien'] as num)
          .toDouble(),
      maKhuyenMai:
      json['maKhuyenMai'],
      ngayLap: DateTime.parse(
        json['ngayLap'],
      ),

      // NEW
      trangThai:
      json['trangThai'] ??
          'CHO_XAC_NHAN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maPhieuDat': maPhieuDat,
      'maNguoiDung': maNguoiDung,
      'maSan': maSan,
      'batDau':
      batDau.toIso8601String(),
      'ketThuc':
      ketThuc.toIso8601String(),
      'tongTien': tongTien,
      'maKhuyenMai':
      maKhuyenMai,
      'ngayLap':
      ngayLap.toIso8601String(),

      // NEW
      'trangThai':
      trangThai,
    };
  }
}