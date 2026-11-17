/// Dữ liệu gửi lên khi tạo hoá đơn.
/// Tổng tiền, mã hoá đơn và ngày lập do server tự tính — không gửi từ client.
class CreateHoaDonRequest {
  final String maPhieuDat;
  final String? maKhuyenMai;
  final String billThanhToan;

  CreateHoaDonRequest({
    required this.maPhieuDat,
    this.maKhuyenMai,
    required this.billThanhToan,
  });

  Map<String, dynamic> toJson() => {
        'maPhieuDat': maPhieuDat,
        'maKhuyenMai': maKhuyenMai,
        'billThanhToan': billThanhToan,
      };
}
