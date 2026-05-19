class KhuyenMaiModel {
  final String maKhuyenMai;
  final String tenKhuyenMai;
  final double phanTramGiam;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;

  KhuyenMaiModel({
    required this.maKhuyenMai,
    required this.tenKhuyenMai,
    required this.phanTramGiam,
    required this.ngayBatDau,
    required this.ngayKetThuc,
  });

  factory KhuyenMaiModel.fromJson(
      Map<String, dynamic> json) {
    return KhuyenMaiModel(
      maKhuyenMai: json['maKhuyenMai'],
      tenKhuyenMai: json['tenKhuyenMai'],
      phanTramGiam:
      (json['phanTramGiam'] as num)
          .toDouble(),
      ngayBatDau:
      DateTime.parse(json['ngayBatDau']),
      ngayKetThuc:
      DateTime.parse(json['ngayKetThuc'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maKhuyenMai': maKhuyenMai,
      'tenKhuyenMai': tenKhuyenMai,
      'phanTramGiam': phanTramGiam,
      'ngayBatDau':
      ngayBatDau.toIso8601String(),
      'ngayKetThuc':
      ngayKetThuc.toIso8601String()
    };
  }
}