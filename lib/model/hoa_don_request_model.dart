class CreateHoaDonRequest {
  final String maHoaDon;
  final String maPhieuDat;
  final String? maKhuyenMai;
  final double tongTien;
  final String ngayLap;
  final String billThanhToan;

  CreateHoaDonRequest({
    required this.maHoaDon,
    required this.maPhieuDat,
    this.maKhuyenMai,
    required this.tongTien,
    required this.ngayLap,
    required this.billThanhToan,
  });

  Map<String, dynamic> toJson() => {
    'maHoaDon': maHoaDon,
    'maPhieuDat': maPhieuDat,
    'maKhuyenMai': maKhuyenMai,
    'tongTien': tongTien,
    'ngayLap': ngayLap,
    'billThanhToan': billThanhToan,
  };
}