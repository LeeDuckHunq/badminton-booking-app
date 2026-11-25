/// Một khung giá của sân: áp dụng cho các thứ [thu] (1 = Thứ Hai … 7 = Chủ Nhật),
/// từ [tuGio] đến trước [denGio] ("HH:mm", denGio có thể là "24:00").
class KhungGia {
  final List<int> thu;
  final String tuGio;
  final String denGio;
  final double gia;
  final String? ten;

  const KhungGia({required this.thu, required this.tuGio, required this.denGio, required this.gia, this.ten});

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  int get fromMinute => _minutes(tuGio);
  int get toMinute => _minutes(denGio);

  bool appliesAt(DateTime t) {
    final m = t.hour * 60 + t.minute;
    return thu.contains(t.weekday) && m >= fromMinute && m < toMinute;
  }

  factory KhungGia.fromJson(Map<String, dynamic> j) => KhungGia(
        thu: ((j['thu'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        tuGio: j['tuGio'] as String? ?? '00:00',
        denGio: j['denGio'] as String? ?? '24:00',
        gia: (j['gia'] as num?)?.toDouble() ?? 0,
        ten: j['ten'] as String?,
      );

  Map<String, dynamic> toJson() => {'thu': thu, 'tuGio': tuGio, 'denGio': denGio, 'gia': gia, 'ten': ten};

  /// [1,2,3,4,5] → "T2–T6"; [6,7] → "T7, CN"; cả tuần → "Hằng ngày".
  String get daysLabel {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final days = thu.toSet().toList()..sort();
    if (days.length == 7) return 'Hằng ngày';
    final runs = <List<int>>[];
    for (final d in days) {
      if (runs.isNotEmpty && d == runs.last[1] + 1) {
        runs.last[1] = d;
      } else {
        runs.add([d, d]);
      }
    }
    return runs.map((r) {
      final a = names[r[0] - 1], b = names[r[1] - 1];
      if (r[1] - r[0] >= 2) return '$a–$b';
      return r[0] == r[1] ? a : '$a, $b';
    }).join(', ');
  }
}

/// Một đoạn liên tiếp cùng giá trong lượt đặt.
class PriceSegment {
  final DateTime from;
  DateTime to;
  final double gia;
  final String? ten;
  PriceSegment(this.from, this.to, this.gia, this.ten);

  double get amount => (gia * to.difference(from).inMinutes / 60).roundToDouble();
}

class SanModel {
  final String maSan;
  final String tenSan;

  /// Giá mặc định mỗi giờ (giờ không thuộc khung giá nào).
  final double gia;
  final bool trangThai;
  final String maCumSan;
  final List<KhungGia> bangGia;

  SanModel({
    required this.maSan,
    required this.tenSan,
    required this.gia,
    required this.trangThai,
    required this.maCumSan,
    this.bangGia = const [],
  });

  factory SanModel.fromJson(Map<String, dynamic> json) {
    return SanModel(
      maSan: json['maSan'],
      tenSan: json['tenSan'],
      gia: (json['gia'] as num).toDouble(),
      trangThai: json['trangThai'],
      maCumSan: json['maCumSan'],
      bangGia: ((json['bangGia'] as List?) ?? []).map((e) => KhungGia.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maSan': maSan,
      'tenSan': tenSan,
      'gia': gia,
      'trangThai': trangThai,
      'maCumSan': maCumSan,
      'bangGia': bangGia.map((r) => r.toJson()).toList(),
    };
  }

  bool get hasTimePricing => bangGia.isNotEmpty;

  KhungGia? ruleAt(DateTime t) {
    for (final r in bangGia) {
      if (r.appliesAt(t)) return r;
    }
    return null;
  }

  /// Giá mỗi giờ tại thời điểm [t].
  double rateAt(DateTime t) => ruleAt(t)?.gia ?? gia;

  /// Tổng tiền [start, end) tính theo từng phút, làm tròn đến đồng (giống BE).
  double priceOf(DateTime start, DateTime end) {
    if (bangGia.isEmpty) return (gia * end.difference(start).inMinutes / 60).roundToDouble();
    double sum = 0;
    for (var t = start; t.isBefore(end); t = t.add(const Duration(minutes: 1))) {
      sum += rateAt(t) / 60;
    }
    return sum.roundToDouble();
  }

  /// Chia lượt đặt thành các đoạn cùng giá.
  List<PriceSegment> breakdown(DateTime start, DateTime end) {
    final parts = <PriceSegment>[];
    for (var t = start; t.isBefore(end); t = t.add(const Duration(minutes: 30))) {
      final to = t.add(const Duration(minutes: 30)).isAfter(end) ? end : t.add(const Duration(minutes: 30));
      final rule = ruleAt(t);
      final g = rule?.gia ?? gia;
      if (parts.isNotEmpty && parts.last.gia == g && parts.last.ten == rule?.ten) {
        parts.last.to = to;
      } else {
        parts.add(PriceSegment(t, to, g, rule?.ten));
      }
    }
    return parts;
  }

  double get minRate => [gia, ...bangGia.map((r) => r.gia)].reduce((a, b) => a < b ? a : b);
  double get maxRate => [gia, ...bangGia.map((r) => r.gia)].reduce((a, b) => a > b ? a : b);
}
