import 'dart:io';

import 'package:application/api/account_api.dart';
import 'package:application/api/hoa_don_api.dart';
import 'package:application/api/khuyen_mai_api.dart';
import 'package:application/api/payment_proof_api.dart';
import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/model/hoa_don_request_model.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/user_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../invoice/models/invoice_model.dart';

/// Tài khoản nhận tiền. [vietQrBank] là mã ngân hàng VietQR (null nếu là ví điện tử).
class _Receiver {
  final String label;
  final String bankName;
  final String accountNo;
  final String owner;
  final String? vietQrBank;
  const _Receiver(this.label, this.bankName, this.accountNo, this.owner, this.vietQrBank);
}

const _receivers = [
  _Receiver('MB Bank', 'MB Bank (Quân Đội)', '0383222791', 'LE NGUYEN VIET HUNG', 'MB'),
  _Receiver('Ví MoMo', 'Ví MoMo', '0383222791', 'LE NGUYEN VIET HUNG', null),
];

/// M9 – Thanh toán / hoá đơn đặt sân.
class InvoiceScreen extends StatefulWidget {
  final InvoiceBookingInfo booking;
  final String maPhieuDat;

  const InvoiceScreen({super.key, required this.booking, required this.maPhieuDat});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  UserModel? _user;
  List<KhuyenMaiModel> _promos = [];
  bool _loading = true;

  String? _selectedPromo;
  int _receiverIndex = 0;

  File? _billFile;
  String? _billUrl;
  bool _uploading = false;
  bool _confirming = false;
  bool _paid = false;

  String get _memo => 'SZ ${Fmt.shortCode(widget.maPhieuDat).substring(1)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username == null) throw Exception('missing username');
      final results = await Future.wait([AccountApi.getUser(username), KhuyenMaiApi.getKhuyenMaiTheoUser(username)]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserModel;
        _promos = results[1] as List<KhuyenMaiModel>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  KhuyenMaiModel? get _promo => _promos.where((p) => p.maKhuyenMai == _selectedPromo).firstOrNull;

  double get _total => widget.booking.tongTien * (1 - (_promo?.phanTramGiam ?? 0));

  double get _discount => widget.booking.tongTien - _total;

  // ── Bill ──────────────────────────────────────────────────────────────────

  Future<void> _pickBill() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SzSheetHandle(),
            const SizedBox(height: 4),
            Text('Tải lên bill chuyển khoản', style: AppText.headlineSm()),
            const SizedBox(height: 12),
            _sourceTile(ctx, Icons.camera_alt_outlined, 'Chụp ảnh', ImageSource.camera),
            _sourceTile(ctx, Icons.photo_library_outlined, 'Chọn từ thư viện', ImageSource.gallery),
          ]),
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;

    setState(() {
      _billFile = File(picked.path);
      _uploading = true;
      _billUrl = null;
    });
    final url = await PaymentProofApi.upload(file: _billFile!);
    if (!mounted) return;
    setState(() {
      _billUrl = url;
      _uploading = false;
    });
    if (url == null) showSzSnack(context, 'Tải ảnh thất bại. Vui lòng thử lại!', type: SzToast.error);
  }

  Widget _sourceTile(BuildContext ctx, IconData icon, String label, ImageSource source) => ListTile(
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColor.primary)),
        title: Text(label, style: AppText.labelLg()),
        onTap: () => Navigator.pop(ctx, source),
      );

  // ── Huỷ / xác nhận ────────────────────────────────────────────────────────

  Future<void> _onPopRequested() async {
    if (_paid) {
      Navigator.pop(context);
      return;
    }
    final cancel = await showSzConfirm(
      context,
      title: 'Huỷ đặt sân?',
      message: 'Bạn chưa thanh toán. Quay lại sẽ huỷ phiếu đặt này và nhả khung giờ cho người khác.',
      confirmLabel: 'Huỷ phiếu đặt',
      cancelLabel: 'Ở lại thanh toán',
      icon: Icons.event_busy_rounded,
      destructive: true,
    );
    if (!cancel || !mounted) return;
    try {
      await PhieuDatSanApi.deletePhieuDat(widget.maPhieuDat);
    } catch (e) {
      debugPrint('Lỗi xoá phiếu đặt: $e');
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirm() async {
    if (_billUrl == null) {
      showSzSnack(context, 'Vui lòng tải lên bill thanh toán trước khi xác nhận', type: SzToast.warning);
      return;
    }
    setState(() => _confirming = true);
    final result = await HoaDonApi.createHoaDon(CreateHoaDonRequest(maPhieuDat: widget.maPhieuDat, maKhuyenMai: _selectedPromo, billThanhToan: _billUrl!));
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result.success) {
      setState(() => _paid = true);
      showSzSnack(context, 'Đặt sân thành công! Chủ sân sẽ duyệt đơn sớm.');
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      showSzSnack(context, result.message ?? 'Tạo hoá đơn thất bại. Vui lòng thử lại!', type: SzToast.error);
    }
  }

  // ── Giao diện ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopRequested();
      },
      child: Scaffold(
        appBar: SzTopBar(title: 'Thanh toán đặt sân', onBack: _onPopRequested),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _Steps(),
            const SizedBox(height: 12),
            _holdBanner(),
            const SizedBox(height: 12),
            _userCard(),
            const SizedBox(height: 12),
            _bookingCard(),
            const SizedBox(height: 12),
            _promoCard(),
            const SizedBox(height: 12),
            _paymentCard(),
            const SizedBox(height: 12),
            _billCard(),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColor.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text('Sau khi bạn xác nhận, chủ sân sẽ đối chiếu giao dịch và duyệt đơn. Trạng thái đơn được cập nhật ở mục Sân đã đặt.', style: AppText.bodySm())),
            ]),
          ],
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  Widget _holdBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: const Color(0xFFFCD34D))),
        child: Row(children: [
          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(child: Text('Khung giờ đang được giữ chỗ cho bạn', style: AppText.label(color: const Color(0xFFB45309)))),
          Text(Fmt.shortCode(widget.maPhieuDat), style: AppText.label(color: const Color(0xFFB45309)).copyWith(fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _userCard() {
    final u = _user;
    return SzCard(
      child: Column(children: [
        SzSectionTitle(Icons.person_outline_rounded, 'Thông tin người đặt', trailing: u == null ? null : SzPill('@${u.username}', bold: false)),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: SzSkeleton(height: 60))
        else if (u == null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Không tải được thông tin tài khoản', style: AppText.body(color: AppColor.textMuted)))
        else ...[
          SzInfoRow('Họ và tên', u.fullName.isEmpty ? u.username : u.fullName, strong: true),
          SzInfoRow('Số điện thoại', u.phoneNumber.isEmpty ? 'Chưa cập nhật' : u.phoneNumber),
          SzInfoRow('Email', u.email.isEmpty ? 'Chưa cập nhật' : u.email),
        ],
      ]),
    );
  }

  Widget _bookingCard() {
    final b = widget.booking;
    final slots = (b.tongGio * 2).round();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card, border: const Border(top: BorderSide(color: AppColor.primary, width: 4))),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SzSectionTitle(Icons.sports_tennis_rounded, 'Thông tin đặt sân'),
        const SizedBox(height: 12),
        Text(b.tenCumSan, style: AppText.headlineLg(color: AppColor.primaryDark)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 14, color: AppColor.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(b.diaChi, style: AppText.bodySm())),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(children: [
            SzInfoRow('Sân thi đấu', b.tenSan, valueColor: AppColor.primary),
            SzInfoRow('Khung giờ & ngày', '${b.thoiGian}\n${Fmt.dateLong(b.batDau)}'),
            SzInfoRow('Thời lượng', '${Fmt.hoursCount(b.tongGio)} ($slots khung 30p)'),
            if (b.giaGio != null) SzInfoRow('Đơn giá', '${Fmt.money(b.giaGio!)}/giờ'),
            const Divider(),
            SzInfoRow('Tổng tiền gốc', Fmt.money(b.tongTien), strong: true),
          ]),
        ),
      ]),
    );
  }

  Widget _promoCard() {
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SzSectionTitle(Icons.confirmation_number_outlined, 'Mã khuyến mãi & ưu đãi', trailing: _promos.isEmpty ? null : SzPill('${_promos.length} voucher', bold: false)),
        const SizedBox(height: 12),
        if (_loading)
          const SzSkeleton(height: 64)
        else if (_promos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text('Không có khuyến mãi áp dụng. Săn voucher ở tab Khám phá nhé!', style: AppText.body(color: AppColor.textMuted)),
          )
        else
          for (final p in _promos) ...[
            _PromoOption(promo: p, base: widget.booking.tongTien, selected: p.maKhuyenMai == _selectedPromo, onTap: () => setState(() => _selectedPromo = p.maKhuyenMai == _selectedPromo ? null : p.maKhuyenMai)),
            const SizedBox(height: 8),
          ],
      ]),
    );
  }

  Widget _paymentCard() {
    final r = _receivers[_receiverIndex];
    final qr = r.vietQrBank == null
        ? null
        : 'https://img.vietqr.io/image/${r.vietQrBank}-${r.accountNo}-compact2.png?amount=${_total.round()}&addInfo=${Uri.encodeComponent(_memo)}&accountName=${Uri.encodeComponent(r.owner)}';
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SzSectionTitle(Icons.account_balance_outlined, 'Tài khoản nhận thanh toán'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(children: [
            for (var i = 0; i < _receivers.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _receiverIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: i == _receiverIndex ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: i == _receiverIndex ? AppShadow.card : null),
                    alignment: Alignment.center,
                    child: Text(_receivers[i].label, style: AppText.labelLg(color: i == _receiverIndex ? AppColor.primaryDark : AppColor.textMuted)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SzInfoRow(r.vietQrBank == null ? 'Ví điện tử' : 'Ngân hàng', r.bankName),
            const SizedBox(height: 4),
            Text(r.vietQrBank == null ? 'Số điện thoại' : 'Số tài khoản', style: AppText.body(color: AppColor.textMuted)),
            Row(children: [
              Expanded(child: Text(r.accountNo, style: AppText.stat(size: 26, color: AppColor.primaryDark).copyWith(letterSpacing: 1))),
              _CopyButton(value: r.accountNo, message: 'Đã sao chép số tài khoản'),
            ]),
            SzInfoRow('Chủ tài khoản', r.owner),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF8D6), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFCE38A))),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nội dung chuyển khoản (bắt buộc)', style: AppText.label(color: const Color(0xFFB45309))),
                    const SizedBox(height: 2),
                    Text(_memo, style: AppText.headlineSm()),
                  ]),
                ),
                _CopyButton(value: _memo, message: 'Đã sao chép nội dung chuyển khoản', accent: true),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: qr == null
              ? Column(children: [
                  const Icon(Icons.phone_iphone_rounded, size: 40, color: AppColor.primary),
                  const SizedBox(height: 8),
                  Text('Mở ứng dụng MoMo, chuyển tới số ${r.accountNo} với số tiền ${Fmt.money(_total)} và nội dung "$_memo".', textAlign: TextAlign.center, style: AppText.body()),
                ])
              : Column(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card),
                    child: SzNetworkImage(qr, width: 200, height: 200, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(style: AppText.body(), children: [
                      const TextSpan(text: 'Quét mã để tự động điền đúng số tiền '),
                      TextSpan(text: Fmt.money(_total), style: AppText.labelLg(color: AppColor.primaryDark)),
                      const TextSpan(text: ' và nội dung chuyển khoản'),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                ]),
        ),
      ]),
    );
  }

  Widget _billCard() {
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SzSectionTitle(Icons.receipt_long_outlined, 'Tải lên bill chuyển khoản', trailing: const SzPill('Bắt buộc', bg: AppColor.dangerSoft, fg: AppColor.danger)),
        const SizedBox(height: 8),
        Text('Ảnh xác nhận chuyển khoản giúp chủ sân duyệt đơn và giữ sân cho bạn.', style: AppText.bodySm()),
        const SizedBox(height: 12),
        if (_billFile == null)
          InkWell(
            onTap: _pickBill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColor.borderStrong, width: 1.5)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 34, color: AppColor.primary),
                const SizedBox(height: 6),
                Text('Chạm để chụp hoặc chọn ảnh bill', style: AppText.labelLg(color: AppColor.primaryDark)),
                Text('JPG, PNG, WebP · tối đa 5MB', style: AppText.bodySm()),
              ]),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _billUrl != null ? const Color(0xFFD7FDDB) : AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_billFile!, width: 64, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 80, child: Icon(Icons.image_outlined)))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_uploading)
                    Row(children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text('Đang tải ảnh lên…', style: AppText.label()),
                    ])
                  else if (_billUrl != null)
                    Row(children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text('Đã tải lên thành công', style: AppText.label(color: AppColor.primaryDark)),
                    ])
                  else
                    Row(children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColor.danger),
                      const SizedBox(width: 6),
                      Text('Tải lên thất bại', style: AppText.label(color: AppColor.danger)),
                    ]),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    onPressed: _uploading ? null : _pickBill,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(_billUrl == null && !_uploading ? 'Thử lại / chọn ảnh khác' : 'Đổi ảnh khác', style: AppText.label(color: AppColor.primary)),
                  ),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Text('TỔNG THANH TOÁN', style: AppText.labelSm()),
              if (_promo != null) ...[const SizedBox(width: 6), SzPill('-${(_promo!.phanTramGiam * 100).round()}%', bold: true)],
            ]),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(Fmt.money(_total), style: AppText.stat(size: 24, color: AppColor.primaryDark)),
                if (_discount > 0) ...[
                  const SizedBox(width: 6),
                  Text(Fmt.money(widget.booking.tongTien), style: AppText.bodySm().copyWith(decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ),
            if (_discount > 0) Text('Đã tiết kiệm ${Fmt.money(_discount)}', style: AppText.label(color: AppColor.primary)),
          ]),
        ),
        const SizedBox(width: 12),
        SzButton('Xác nhận', uppercase: true, kind: SzButtonKind.dark, trailingIcon: Icons.arrow_forward_rounded, loading: _confirming, onPressed: _uploading ? null : _confirm),
      ]),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    Widget dot(String label, {bool done = false, bool active = false, required String n}) => Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: done ? AppColor.primaryDark : (active ? AppColor.primaryDark : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(color: done || active ? AppColor.primaryDark : AppColor.border, width: 2),
              boxShadow: active ? [BoxShadow(color: AppColor.primary.withValues(alpha: 0.25), spreadRadius: 4)] : null,
            ),
            alignment: Alignment.center,
            child: done ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : Text(n, style: AppText.label(color: active ? Colors.white : AppColor.textMuted)),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppText.label(color: done || active ? AppColor.text : AppColor.textMuted)),
        ]);
    Widget line(bool on) => Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 22), color: on ? AppColor.primaryDark : AppColor.border));

    return SzCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(children: [
        dot('Chọn giờ', done: true, n: '1'),
        line(true),
        dot('Thanh toán', active: true, n: '2'),
        line(false),
        dot('Chờ duyệt', n: '3'),
      ]),
    );
  }
}

class _PromoOption extends StatelessWidget {
  final KhuyenMaiModel promo;
  final double base;
  final bool selected;
  final VoidCallback onTap;

  const _PromoOption({required this.promo, required this.base, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = (promo.phanTramGiam * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FDDB) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColor.primary : AppColor.border, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: selected ? AppColor.primaryDark : AppColor.mint, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.percent_rounded, color: selected ? Colors.white : AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(promo.tenKhuyenMai.isEmpty ? promo.maKhuyenMai : promo.tenKhuyenMai, style: AppText.labelLg(), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Giảm $percent% · HSD ${Fmt.date(promo.ngayKetThuc)}', style: AppText.bodySm()),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('-${Fmt.money(base * promo.phanTramGiam)}', style: AppText.labelLg(color: AppColor.primaryDark).copyWith(fontWeight: FontWeight.w800)),
            Row(children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: selected ? AppColor.primary : AppColor.textSubtle),
              const SizedBox(width: 4),
              Text(selected ? 'Áp dụng' : 'Chọn', style: AppText.label(color: selected ? AppColor.primary : AppColor.textMuted)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String value;
  final String message;
  final bool accent;
  const _CopyButton({required this.value, required this.message, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? const Color(0xFFFFE170) : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          showSzSnack(context, message);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: accent ? null : Border.all(color: AppColor.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.content_copy_rounded, size: 15, color: accent ? AppColor.text : AppColor.primary),
            const SizedBox(width: 4),
            Text('Sao chép', style: AppText.label(color: accent ? AppColor.text : AppColor.primary)),
          ]),
        ),
      ),
    );
  }
}
