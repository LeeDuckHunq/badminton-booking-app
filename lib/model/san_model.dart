class SanModel {
  final String maSan;
  final String tenSan;
  final double gia;
  final bool trangThai;
  final String maCumSan;

  SanModel({
    required this.maSan,
    required this.tenSan,
    required this.gia,
    required this.trangThai,
    required this.maCumSan,
  });

  factory SanModel.fromJson(Map<String, dynamic> json) {
    return SanModel(
      maSan: json['maSan'],
      tenSan: json['tenSan'],
      gia: (json['gia'] as num).toDouble(),
      trangThai: json['trangThai'],
      maCumSan: json['maCumSan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maSan': maSan,
      'tenSan': tenSan,
      'gia': gia,
      'trangThai': trangThai,
      'maCumSan': maCumSan,
    };
  }
}