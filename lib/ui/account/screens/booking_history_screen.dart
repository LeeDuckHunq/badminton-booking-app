// lib/ui/account/screens/booking_history_screen.dart
import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// M16 – Sân đã đặt (lịch sử đặt sân).
class BookingHistoryScreen extends StatefulWidget {
  final List<PhieuDatSanModel> phieuList;
  final Map<String, SanModel> sanMap;
  final Map<String, CumSanModel> cumSanMap;
  final Map<String, String> images;

  const BookingHistoryScreen({super.key, required this.phieuList, required this.sanMap, required this.cumSanMap, this.images = const {}});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  static const _filters = [
    (null, 'Tất cả', null),
    ('CHO_XAC_NHAN', 'Chờ xác nhận', AppColor.pending),
    ('DA_XAC_NHAN', 'Đã xác nhận', AppColor.confirmed),
    ('DA_HOAN_THANH', 'Hoàn thành', AppColor.completed),
    ('DA_HUY', 'Đã huỷ', AppColor.danger),
  ];
  String? _status;

  CumSanModel? _venueOf(PhieuDatSanModel p) {
    final san = widget.sanMap[p.maSan];
    return san == null ? null : widget.cumSanMap[san.maCumSan];
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.phieuList]..sort((a, b) => b.batDau.compareTo(a.batDau));
    final list = _status == null ? sorted : sorted.where((p) => p.trangThai == _status).toList();

    return Scaffold(
      appBar: const SzTopBar(title: 'Sân đã đặt', subtitle: 'Lịch sử đặt sân của bạn'),
      body: Column(children: [
        Container(
          color: Colors.white,
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              for (final (code, label, dot) in _filters) ...[
                SzChip(label, dot: dot, count: code == null ? widget.phieuList.length : widget.phieuList.where((p) => p.trangThai == code).length, selected: _status == code, onTap: () => setState(() => _status = code)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const SzEmptyState(icon: Icons.event_note_outlined, title: 'Không có phiếu đặt nào', message: 'Các lần đặt sân của bạn sẽ hiển thị tại đây.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    if (i == list.length) {
                      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: AppColor.textMuted),
                        const SizedBox(width: 6),
                        Text('Mọi đơn đặt đều được chủ sân xác nhận trên hệ thống', style: AppText.bodySm()),
                      ]);
                    }
                    final p = list[i];
                    final venue = _venueOf(p);
                    return _BookingTicket(
                      phieu: p,
                      san: widget.sanMap[p.maSan],
                      venue: venue,
                      image: venue == null ? null : widget.images[venue.maCumSan],
                      onInvoice: () => showInvoiceSheet(context, p, widget.sanMap[p.maSan], venue),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _BookingTicket extends StatelessWidget {
  final PhieuDatSanModel phieu;
  final SanModel? san;
  final CumSanModel? venue;
  final String? image;
  final VoidCallback onInvoice;

  const _BookingTicket({required this.phieu, required this.san, required this.venue, required this.image, required this.onInvoice});

  @override
  Widget build(BuildContext context) {
    final s = BookingStatus.of(phieu.trangThai);
    final cancelled = phieu.trangThai == 'DA_HUY';
    final hours = phieu.ketThuc.difference(phieu.batDau).inMinutes / 60;
    final now = DateTime.now();
    final daysLeft = DateTime(phieu.batDau.year, phieu.batDau.month, phieu.batDau.day).difference(DateTime(now.year, now.month, now.day)).inDays;

    final (hintIcon, hintText, hintBg, hintFg) = switch (phieu.trangThai) {
      'DA_XAC_NHAN' when phieu.isWalkIn && phieu.ketThuc.isAfter(now) => (Icons.storefront_outlined, 'Đặt tại sân · ${phieu.phuongThucLabel}', AppColor.mint, AppColor.primaryDark),
      'CHO_XAC_NHAN' => (Icons.receipt_long_outlined, 'Chờ chủ sân duyệt thanh toán', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      'DA_XAC_NHAN' when phieu.ketThuc.isAfter(now) => (Icons.alarm_rounded, daysLeft <= 0 ? 'Lịch hôm nay' : 'Lịch sắp tới · Còn $daysLeft ngày', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'DA_XAC_NHAN' => (Icons.event_available_rounded, 'Đã qua giờ chơi', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'DA_HOAN_THANH' => (Icons.sports_score_rounded, 'Đã kết thúc lượt chơi', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'DA_HUY' => (Icons.info_outline_rounded, 'Đơn đã bị huỷ', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (Icons.help_outline_rounded, 'Không xác định', AppColor.slot, AppColor.textMuted),
    };

    final venueName = venue?.tenCumSan ?? 'Cụm sân';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: s.accent),
          Expanded(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(Fmt.shortCode(phieu.maPhieuDat), style: AppText.headlineSm(color: cancelled ? AppColor.textMuted : AppColor.text)),
                    const SizedBox(width: 2),
                    SzIconButton(Icons.content_copy_rounded, size: 30, color: AppColor.textMuted, onPressed: () {
                      Clipboard.setData(ClipboardData(text: phieu.maPhieuDat));
                      showSzSnack(context, 'Đã sao chép mã phiếu');
                    }),
                    const Spacer(),
                    StatusBadge(phieu.trangThai),
                  ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: cancelled
                          ? Container(width: 72, height: 72, color: const Color(0xFF1F2937), child: const Icon(Icons.block_rounded, color: Colors.white70))
                          : SzNetworkImage(image, width: 72, height: 72),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          venueName,
                          style: AppText.headlineSm(color: cancelled ? AppColor.textMuted : AppColor.forest).copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(san?.tenSan ?? phieu.maSan, style: AppText.body(color: AppColor.textMuted)),
                        const SizedBox(height: 4),
                        _line(Icons.calendar_today_outlined, Fmt.dateLong(phieu.batDau)),
                        _line(Icons.schedule_rounded, '${Fmt.range(phieu.batDau, phieu.ketThuc)} (${Fmt.hoursCount(hours)})'),
                      ]),
                    ),
                  ]),
                ]),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: SzDashedDivider()),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: hintBg, borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(hintIcon, size: 14, color: hintFg),
                            const SizedBox(width: 4),
                            Flexible(child: Text(hintText, style: AppText.label(color: hintFg), overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Fmt.money(phieu.tongTien),
                      style: AppText.stat(size: 20, color: cancelled ? AppColor.textMuted : AppColor.primaryDark).copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _actions(context),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColor.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppText.bodySm(color: AppColor.text))),
        ]),
      );

  Widget _actions(BuildContext context) {
    final invoice = SzButton.small('Xem hoá đơn', icon: Icons.receipt_long_outlined, kind: SzButtonKind.soft, expand: true, onPressed: onInvoice);
    switch (phieu.trangThai) {
      case 'DA_XAC_NHAN':
        return Row(children: [
          Expanded(child: invoice),
          const SizedBox(width: 8),
          Expanded(
            child: SzButton.small('Chỉ đường', icon: Icons.near_me_outlined, expand: true, onPressed: venue == null ? null : () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(venue!.diaChi)}'), mode: LaunchMode.externalApplication)),
          ),
        ]);
      case 'DA_HOAN_THANH':
      case 'DA_HUY':
        return Row(children: [
          Expanded(child: invoice),
          const SizedBox(width: 8),
          Expanded(
            child: SzButton.small('Đặt lại sân', icon: Icons.replay_rounded, kind: SzButtonKind.dark, expand: true, onPressed: venue == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScheduleScreen(cumSan: venue!)))),
          ),
        ]);
      default:
        return SzButton.small('Xem hoá đơn', icon: Icons.receipt_long_outlined, kind: SzButtonKind.dark, expand: true, trailingIcon: Icons.arrow_forward_rounded, onPressed: onInvoice);
    }
  }
}

// ═══════════════════════════════ M17 – CHI TIẾT HOÁ ĐƠN ═══════════════════════════════

class HoaDonModel {
  final String maHoaDon;
  final String maPhieuDat;
  final String? maKhuyenMai;
  final double tongTien;
  final DateTime ngayLap;
  final String? billThanhToan;

  HoaDonModel({required this.maHoaDon, required this.maPhieuDat, this.maKhuyenMai, required this.tongTien, required this.ngayLap, this.billThanhToan});

  factory HoaDonModel.fromJson(Map<String, dynamic> json) => HoaDonModel(
        maHoaDon: json['maHoaDon'] as String? ?? '',
        maPhieuDat: json['maPhieuDat'] as String? ?? '',
        maKhuyenMai: json['maKhuyenMai'] as String?,
        tongTien: (json['tongTien'] as num?)?.toDouble() ?? 0,
        ngayLap: DateTime.tryParse('${json['ngayLap']}') ?? DateTime.now(),
        billThanhToan: json['billThanhToan'] as String?,
      );
}

Future<void> showInvoiceSheet(BuildContext context, PhieuDatSanModel phieu, SanModel? san, CumSanModel? venue) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _InvoiceSheet(phieu: phieu, san: san, venue: venue),
  );
}

class _InvoiceSheet extends StatefulWidget {
  final PhieuDatSanModel phieu;
  final SanModel? san;
  final CumSanModel? venue;

  const _InvoiceSheet({required this.phieu, required this.san, required this.venue});

  @override
  State<_InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<_InvoiceSheet> {
  HoaDonModel? _hoaDon;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/hoa-don/get-hoa-don/${Uri.encodeComponent(widget.phieu.maPhieuDat)}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _hoaDon = HoaDonModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.statusCode != 404
              ? 'Lỗi ${res.statusCode}'
              : widget.phieu.isWalkIn
                  ? 'Đơn do chủ sân đặt hộ tại sân · Thanh toán: ${widget.phieu.phuongThucLabel}.'
                  : 'Phiếu đặt này chưa có hoá đơn (chưa thanh toán).';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải hoá đơn';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.phieu;
    final s = BookingStatus.of(p.trangThai);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SzSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
          child: Row(children: [
            SzIconButton(Icons.close_rounded, onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 4),
            Text('Chi tiết hoá đơn', style: AppText.headlineMd()),
            const SizedBox(width: 8),
            StatusBadge(p.trangThai),
          ]),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle), child: Icon(s.icon, color: s.fg)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Đơn ${Fmt.shortCode(p.maPhieuDat)}', style: AppText.headlineMd()),
                      Text(s.label, style: AppText.label(color: s.fg)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Tổng tiền', style: AppText.bodySm()),
                    Text(Fmt.money(_hoaDon?.tongTien ?? p.tongTien), style: AppText.stat(size: 22, color: AppColor.primaryDark)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: SzLoading(message: 'Đang tải hoá đơn…'))
              else if (_error != null)
                _venueBlock(includePrice: false, footer: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppColor.pending, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: AppText.body(color: AppColor.textMuted))),
                    TextButton(onPressed: _fetch, child: const Text('Thử lại')),
                  ]),
                ))
              else
                _venueBlock(includePrice: true),
              if (_hoaDon?.billThanhToan != null) ...[
                const SizedBox(height: 12),
                SzCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SzSectionTitle(Icons.image_outlined, 'Bill thanh toán'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _zoom(context, _hoaDon!.billThanhToan!),
                      child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SzNetworkImage(_hoaDon!.billThanhToan, height: 260, width: double.infinity, fit: BoxFit.cover)),
                    ),
                    const SizedBox(height: 6),
                    Text('Chạm để phóng to', style: AppText.bodySm()),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _venueBlock({required bool includePrice, Widget? footer}) {
    final p = widget.phieu;
    final hd = _hoaDon;
    final hours = p.ketThuc.difference(p.batDau).inMinutes / 60;
    final discount = hd == null ? 0.0 : (p.tongTien - hd.tongTien).clamp(0, double.infinity).toDouble();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card, border: const Border(top: BorderSide(color: AppColor.primary, width: 4))),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (hd != null) ...[
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.receipt_outlined, size: 15, color: AppColor.textMuted),
                  const SizedBox(width: 4),
                  Text('MÃ HOÁ ĐƠN', style: AppText.labelSm()),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(child: Text(Fmt.shortCode(hd.maHoaDon.replaceFirst('HD_', '')).replaceFirst('#', 'HD-'), style: AppText.headlineSm())),
                  SzIconButton(Icons.content_copy_rounded, size: 32, color: AppColor.primary, onPressed: () {
                    Clipboard.setData(ClipboardData(text: hd.maHoaDon));
                    showSzSnack(context, 'Đã sao chép mã hoá đơn');
                  }),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Thời gian tạo', style: AppText.bodySm()),
              Text('${Fmt.date(hd.ngayLap)} · ${Fmt.hhmm(hd.ngayLap)}', style: AppText.labelLg()),
            ]),
          ]),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.venue?.tenCumSan ?? 'Cụm sân', style: AppText.headlineSm(color: AppColor.primaryDark)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.sports_tennis_rounded, size: 15, color: AppColor.textMuted),
              const SizedBox(width: 6),
              Text(widget.san?.tenSan ?? p.maSan, style: AppText.labelLg()),
            ]),
            if (widget.venue != null) ...[
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColor.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.venue!.diaChi, style: AppText.body(color: AppColor.textMuted))),
              ]),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _miniBox(Icons.calendar_today_rounded, 'NGÀY ĐẤU', Fmt.dateShort(p.batDau))),
              const SizedBox(width: 8),
              Expanded(child: _miniBox(Icons.schedule_rounded, 'KHUNG GIỜ', Fmt.range(p.batDau, p.ketThuc))),
            ]),
            const SizedBox(height: 8),
            Text('Thời lượng: ${Fmt.hoursCount(hours)} (${(hours * 2).round()} khung 30 phút)', style: AppText.bodySm()),
          ]),
        ),
        if (includePrice && hd != null) ...[
          const SizedBox(height: 14),
          const SzDashedDivider(),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.payments_outlined, size: 18, color: AppColor.textMuted),
            const SizedBox(width: 6),
            Text('CHI TIẾT GIÁ & THANH TOÁN', style: AppText.labelSm()),
          ]),
          const SizedBox(height: 6),
          SzInfoRow('Giá thuê sân (${Fmt.hoursCount(hours)})', Fmt.money(p.tongTien)),
          if (hd.maKhuyenMai != null) SzInfoRow('Voucher ${hd.maKhuyenMai}', '-${Fmt.money(discount)}', valueColor: AppColor.primary),
          SzInfoRow('Phương thức', 'Chuyển khoản'),
          const Divider(),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tổng thanh toán', style: AppText.headlineSm()),
                Text(BookingStatus.of(p.trangThai).label, style: AppText.label(color: BookingStatus.of(p.trangThai).fg)),
              ]),
            ),
            Text(Fmt.money(hd.tongTien), style: AppText.stat(size: 24, color: AppColor.primaryDark)),
          ]),
        ],
        if (footer != null) footer,
      ]),
    );
  }

  Widget _miniBox(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: const BoxDecoration(color: AppColor.mint, shape: BoxShape.circle), child: Icon(icon, size: 18, color: AppColor.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppText.labelSm()),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppText.labelLg(), maxLines: 1)),
            ]),
          ),
        ]),
      );

  void _zoom(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(children: [
          InteractiveViewer(child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Text('Không tải được ảnh', style: TextStyle(color: Colors.white)))))),
          Positioned(top: 4, right: 4, child: SzIconButton(Icons.close_rounded, color: Colors.white, onPressed: () => Navigator.pop(ctx))),
        ]),
      ),
    );
  }
}
