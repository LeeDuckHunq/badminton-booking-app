class KhuyenMaiModel {
  final String maKhuyenMai;
  final String tenKhuyenMai;
  final String duongDanAnh;
  final double phanTramGiam;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;

  KhuyenMaiModel({
    required this.maKhuyenMai,
    required this.tenKhuyenMai,
    required this.duongDanAnh,
    required this.phanTramGiam,
    required this.ngayBatDau,
    required this.ngayKetThuc,
  });

  factory KhuyenMaiModel.fromJson(
      Map<String, dynamic> json) {
    return KhuyenMaiModel(
      maKhuyenMai:
      json['maKhuyenMai'] ?? '',

      tenKhuyenMai:
      json['tenKhuyenMai'] ?? '',

      duongDanAnh:
      json['duongDanAnh'] ?? '',

      phanTramGiam:
      (json['phanTramGiam'] as num?)
          ?.toDouble() ??
          0.0,

      ngayBatDau: DateTime.parse(
        json['ngayBatDau'],
      ),

      ngayKetThuc: DateTime.parse(
        json['ngayKetThuc'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maKhuyenMai': maKhuyenMai,
      'tenKhuyenMai': tenKhuyenMai,
      'duongDanAnh': duongDanAnh,
      'phanTramGiam': phanTramGiam,
      'ngayBatDau':
      ngayBatDau.toIso8601String(),
      'ngayKetThuc':
      ngayKetThuc.toIso8601String(),
    };
  }

  KhuyenMaiModel copyWith({
    String? maKhuyenMai,
    String? tenKhuyenMai,
    String? duongDanAnh,
    double? phanTramGiam,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
  }) {
    return KhuyenMaiModel(
      maKhuyenMai:
      maKhuyenMai ??
          this.maKhuyenMai,
      tenKhuyenMai:
      tenKhuyenMai ??
          this.tenKhuyenMai,
      duongDanAnh:
      duongDanAnh ??
          this.duongDanAnh,
      phanTramGiam:
      phanTramGiam ??
          this.phanTramGiam,
      ngayBatDau:
      ngayBatDau ??
          this.ngayBatDau,
      ngayKetThuc:
      ngayKetThuc ??
          this.ngayKetThuc,
    );
  }
}