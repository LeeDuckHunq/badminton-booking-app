// Thẻ voucher dạng vé (có lỗ khuyết và đường đục lỗ) dùng ở Kho voucher và Voucher của tôi.
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

class VoucherTicket extends StatelessWidget {
  final KhuyenMaiModel voucher;
  final Widget action;
  final bool dimmed;
  final String? stubLabel;

  const VoucherTicket({super.key, required this.voucher, required this.action, this.dimmed = false, this.stubLabel});

  int get daysLeft => voucher.ngayKetThuc.difference(DateTime.now()).inHours ~/ 24;

  bool get expired => voucher.ngayKetThuc.isBefore(DateTime.now());

  bool get expiringSoon => !expired && daysLeft <= 3;

  @override
  Widget build(BuildContext context) {
    final percent = (voucher.phanTramGiam * 100).round();
    final (stubBg, stubFg) = dimmed
        ? (const Color(0xFFF1F5F9), AppColor.textSubtle)
        : expiringSoon
            ? (const Color(0xFFFEE2E2), const Color(0xFFB91C1C))
            : (const Color(0xFFD7FDDB), AppColor.primaryDark);

    return Opacity(
      opacity: dimmed ? 0.7 : 1,
      child: ClipPath(
        clipper: _TicketClipper(stubWidth: 112),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadow.card, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 112,
                color: stubBg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(stubLabel ?? 'VOUCHER', style: AppText.labelSm(color: stubFg)),
                  const SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('$percent', style: AppText.stat(size: 38, color: stubFg)),
                    Text('%', style: AppText.headlineMd(color: stubFg)),
                  ]),
                  Text('GIẢM GIÁ', style: AppText.labelSm(color: stubFg)),
                ]),
              ),
              CustomPaint(size: const Size(2, double.infinity), painter: _DashPainter()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _statusPill(),
                    const SizedBox(height: 8),
                    Text(voucher.tenKhuyenMai.isEmpty ? 'Voucher giảm $percent%' : voucher.tenKhuyenMai, style: AppText.headlineSm(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColor.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text('${Fmt.date(voucher.ngayBatDau).substring(0, 5)} – ${Fmt.date(voucher.ngayKetThuc)}', style: AppText.bodySm())),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text('Mã: ${voucher.maKhuyenMai}', style: AppText.label(color: AppColor.textMuted), overflow: TextOverflow.ellipsis)),
                      action,
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statusPill() {
    if (expired) return const SzPill('Hết hạn', bg: Color(0xFFF1F5F9), fg: AppColor.textMuted, icon: Icons.history_toggle_off_rounded);
    if (expiringSoon) return SzPill(daysLeft <= 0 ? 'Hết hạn hôm nay' : 'Sắp hết · còn $daysLeft ngày', bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C), icon: Icons.alarm_rounded);
    return SzPill('Còn $daysLeft ngày', bg: const Color(0xFFFFF4B8), fg: AppColor.text, icon: Icons.timer_outlined);
  }
}

/// Khoét 2 nửa hình tròn ở mép trên/dưới, ngay đường nối cuống vé.
class _TicketClipper extends CustomClipper<Path> {
  final double stubWidth;
  _TicketClipper({required this.stubWidth});

  @override
  Path getClip(Size size) {
    const r = 9.0;
    final rect = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(stubWidth + 1, 0), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(stubWidth + 1, size.height), radius: r));
    return Path.combine(PathOperation.difference, rect, holes);
  }

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) => oldClipper.stubWidth != stubWidth;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColor.borderStrong
      ..strokeWidth = 2;
    for (double y = 12; y < size.height - 12; y += 8) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
