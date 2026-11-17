// lib/ui/screen/ClaimVoucherScreen.dart
import 'package:application/api/claim_voucher_api.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/claim_voucher/widgets/confetti_overlay.dart';
import 'package:application/ui/claim_voucher/widgets/voucher_card.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _VFilter { all, expiring, big }

/// M13 – Kho voucher (tab Khám phá).
class ClaimVoucherScreen extends StatefulWidget {
  const ClaimVoucherScreen({super.key});

  @override
  State<ClaimVoucherScreen> createState() => _ClaimVoucherScreenState();
}

class _ClaimVoucherScreenState extends State<ClaimVoucherScreen> with SingleTickerProviderStateMixin {
  List<KhuyenMaiModel> _vouchers = [];
  bool _loading = true;
  bool _failed = false;
  String _username = '';
  final Set<String> _claiming = {};
  _VFilter _filter = _VFilter.all;
  final _codeCtrl = TextEditingController();
  bool _redeeming = false;

  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';
    await _load();
  }

  Future<void> _load() async {
    if (_username.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final list = await ClaimVoucherApi.getAvailableVouchers(_username);
    if (!mounted) return;
    setState(() {
      _vouchers = list ?? [];
      _failed = list == null;
      _loading = false;
    });
  }

  List<KhuyenMaiModel> get _visible {
    final now = DateTime.now();
    final list = _vouchers.where((v) => switch (_filter) {
          _VFilter.all => true,
          _VFilter.expiring => v.ngayKetThuc.difference(now).inDays <= 3,
          _VFilter.big => v.phanTramGiam >= 0.2,
        }).toList();
    list.sort((a, b) => a.ngayKetThuc.compareTo(b.ngayKetThuc));
    return list;
  }

  Future<void> _claim(String code) async {
    final result = await ClaimVoucherApi.claimVoucher(maKhuyenMai: code);
    if (!mounted) return;
    if (result.ok) {
      _confetti.forward(from: 0);
      showSzSnack(context, '🎉 ${result.message}! Voucher đã vào ví của bạn.');
      await _load();
    } else {
      showSzSnack(context, result.message, type: SzToast.error);
    }
  }

  Future<void> _claimVoucher(KhuyenMaiModel v) async {
    if (_claiming.contains(v.maKhuyenMai)) return;
    setState(() => _claiming.add(v.maKhuyenMai));
    await _claim(v.maKhuyenMai);
    if (mounted) setState(() => _claiming.remove(v.maKhuyenMai));
  }

  Future<void> _redeemCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      showSzSnack(context, 'Nhập mã voucher trước nhé', type: SzToast.warning);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _redeeming = true);
    await _claim(code);
    if (!mounted) return;
    setState(() => _redeeming = false);
    _codeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    final now = DateTime.now();
    final expiringCount = _vouchers.where((v) => v.ngayKetThuc.difference(now).inDays <= 3).length;
    final bigCount = _vouchers.where((v) => v.phanTramGiam >= 0.2).length;

    return Scaffold(
      body: Stack(children: [
        Column(children: [
          const SzBrandHeader(subtitle: 'Khám phá'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Hero(count: _vouchers.length, loading: _loading),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      SzChip('Tất cả', count: _vouchers.length, selected: _filter == _VFilter.all, onTap: () => setState(() => _filter = _VFilter.all)),
                      const SizedBox(width: 8),
                      SzChip('Sắp hết hạn', icon: Icons.alarm_rounded, count: expiringCount, selected: _filter == _VFilter.expiring, onTap: () => setState(() => _filter = _VFilter.expiring)),
                      const SizedBox(width: 8),
                      SzChip('Giảm từ 20%', icon: Icons.local_fire_department_outlined, count: bigCount, selected: _filter == _VFilter.big, onTap: () => setState(() => _filter = _VFilter.big)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SzSkeleton(height: 130, radius: AppRadius.lg))
                  else if (_failed)
                    SzErrorState(message: 'Không tải được kho voucher.', onRetry: _load)
                  else if (list.isEmpty)
                    SzEmptyState(
                      icon: Icons.redeem_rounded,
                      title: _vouchers.isEmpty ? 'Hết voucher rồi!' : 'Không có voucher phù hợp',
                      message: _vouchers.isEmpty ? 'Bạn đã nhận hết voucher đang mở. Quay lại sau để săn deal mới nhé.' : 'Thử chọn bộ lọc khác.',
                    )
                  else
                    for (final v in list) ...[
                      VoucherTicket(
                        voucher: v,
                        action: SzButton.small(
                          'Lấy ngay',
                          uppercase: true,
                          kind: SzButtonKind.dark,
                          loading: _claiming.contains(v.maKhuyenMai),
                          onPressed: () => _claimVoucher(v),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 8),
                  _codeCard(),
                ],
              ),
            ),
          ),
        ]),
        Positioned.fill(child: AnimatedBuilder(animation: _confetti, builder: (_, __) => ConfettiOverlay(progress: _confetti.value))),
      ]),
    );
  }

  Widget _codeCard() {
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.card_giftcard_rounded, color: AppColor.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nhập mã voucher', style: AppText.headlineSm()),
              const SizedBox(height: 2),
              Text('Có mã từ chủ sân hoặc sự kiện? Nhập vào đây để nạp thẳng vào ví.', style: AppText.bodySm()),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SzTextField(controller: _codeCtrl, hint: 'VD: KM10', icon: Icons.sell_outlined, textInputAction: TextInputAction.done, onSubmitted: (_) => _redeemCode())),
          const SizedBox(width: 8),
          SzButton('Áp dụng', kind: SzButtonKind.dark, loading: _redeeming, onPressed: _redeemCode),
        ]),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final int count;
  final bool loading;
  const _Hero({required this.count, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [AppColor.primaryDark, AppColor.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: AppShadow.primaryGlow,
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SzPill.accent('ƯU ĐÃI ĐỘC QUYỀN', icon: Icons.bolt_rounded),
            const SizedBox(height: 10),
            Text('Kho Voucher\nSăn Deal Sân', style: AppText.display(color: Colors.white).copyWith(fontSize: 26, height: 1.2)),
            const SizedBox(height: 6),
            Text('Nhận miễn phí, áp dụng khi thanh toán đặt sân.', style: AppText.body(color: const Color(0xFFCFF5D6))),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.confirmation_number_rounded, color: AppColor.accent, size: 28),
            const SizedBox(height: 4),
            Text(loading ? '…' : '$count', style: AppText.stat(size: 24, color: Colors.white)),
            Text('mã đang mở', style: AppText.labelSm(color: const Color(0xFFCFF5D6))),
          ]),
        ),
      ]),
    );
  }
}
