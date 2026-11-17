import 'package:application/ui/widget/sz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt', () {
    test('money uses dot separators and dong sign', () {
      expect(Fmt.money(150000), '150.000 ₫');
      expect(Fmt.money(1200000), '1.200.000 ₫');
    });

    test('time strips seconds and pads', () {
      expect(Fmt.time('05:00:00'), '05:00');
      expect(Fmt.time('7:5'), '07:05');
      expect(Fmt.hours('05:00:00', '23:00:00'), '05:00 – 23:00');
    });

    test('hoursCount uses Vietnamese decimal comma', () {
      expect(Fmt.hoursCount(1.5), '1,5 giờ');
      expect(Fmt.hoursCount(2), '2 giờ');
    });

    test('dates', () {
      final d = DateTime(2026, 11, 18);
      expect(Fmt.date(d), '18/11/2026');
      expect(Fmt.dateShort(d), 'T4, 18/11');
      expect(Fmt.dateLong(d), 'Thứ Tư, 18/11/2026');
    });

    test('shortCode and initials', () {
      expect(Fmt.shortCode('PD_2520d1fa-f145-4d92'), '#2520D1FA');
      expect(Fmt.initials('Nguyễn Tuấn Anh'), 'TA');
      expect(Fmt.initials('alice'), 'AL');
    });
  });

  test('BookingStatus maps all four states', () {
    expect(BookingStatus.of('CHO_XAC_NHAN').label, 'Chờ xác nhận');
    expect(BookingStatus.of('DA_XAC_NHAN').label, 'Đã xác nhận');
    expect(BookingStatus.of('DA_HOAN_THANH').label, 'Hoàn thành');
    expect(BookingStatus.of('DA_HUY').label, 'Đã huỷ');
  });
}
