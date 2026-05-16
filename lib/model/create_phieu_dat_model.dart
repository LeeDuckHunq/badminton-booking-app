class CreatePhieuDatModel {
  final String maNguoiDung;
  final String maSan;
  final DateTime batDau;
  final DateTime ketThuc;
  final String? maKhuyenMai;

  CreatePhieuDatModel({
    required this.maNguoiDung,
    required this.maSan,
    required this.batDau,
    required this.ketThuc,
    this.maKhuyenMai,
  });

  Map<String, dynamic> toJson() {
    return {
      'maNguoiDung': maNguoiDung,
      'maSan': maSan,
      'batDau': batDau.toIso8601String(),
      'ketThuc': ketThuc.toIso8601String(),
      'maKhuyenMai': maKhuyenMai,
    };
  }
}