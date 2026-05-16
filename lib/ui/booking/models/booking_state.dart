// lib/ui/booking/models/booking_state.dart

import 'package:flutter/material.dart';
import 'package:application/model/san_model.dart';

/// Trạng thái của 1 ô time slot trong grid
enum SlotStatus {
  available,  // trắng/xanh nhạt — còn trống
  booked,     // đỏ            — đã được đặt
  locked,     // xám           — ngoài giờ / khoá
  selected,   // xanh lá nhạt  — đang chọn
}

/// Đại diện 1 ô trong grid (1 sân × 1 khoảng 30p)
class TimeSlot {
  final String maSan;
  final DateTime start;
  final DateTime end;
  final SlotStatus status;

  const TimeSlot({
    required this.maSan,
    required this.start,
    required this.end,
    required this.status,
  });

  TimeSlot copyWith({SlotStatus? status}) => TimeSlot(
    maSan: maSan,
    start: start,
    end: end,
    status: status ?? this.status,
  );

  bool get isSelectable => status == SlotStatus.available;
}

/// Kết quả selection của user
class BookingSelection {
  final SanModel san;
  final DateTime batDau;
  final DateTime ketThuc;

  const BookingSelection({
    required this.san,
    required this.batDau,
    required this.ketThuc,
  });

  Duration get duration => ketThuc.difference(batDau);

  double get tongGio => duration.inMinutes / 60.0;

  double get tongTien => tongGio * san.gia;

  String get thoiGianHienThi {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(batDau)} – ${fmt(ketThuc)}';
  }
}