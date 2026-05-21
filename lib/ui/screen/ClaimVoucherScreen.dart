// lib/ui/account/screens/claim_voucher/claim_voucher_screen.dart

import 'package:application/api/claim_voucher_api.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/claim_voucher/widgets/confetti_overlay.dart';
import 'package:application/ui/claim_voucher/widgets/voucher_card.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClaimVoucherScreen extends StatefulWidget {
  const ClaimVoucherScreen({super.key});

  @override
  State<ClaimVoucherScreen> createState() => _ClaimVoucherScreenState();
}

class _ClaimVoucherScreenState extends State<ClaimVoucherScreen>
    with SingleTickerProviderStateMixin {
  List<KhuyenMaiModel> _vouchers = [];
  bool _isLoading = true;
  String? _username;
  final Set<String> _claiming = {};

  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _init();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';
    await _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    if (_username == null || _username!.isEmpty) return;
    setState(() => _isLoading = true);
    final list = await ClaimVoucherApi.getAvailableVouchers(_username!);
    if (!mounted) return;
    setState(() {
      _vouchers = list;
      _isLoading = false;
    });
  }

  Future<void> _claimVoucher(KhuyenMaiModel voucher) async {
    if (_claiming.contains(voucher.maKhuyenMai)) return;
    setState(() => _claiming.add(voucher.maKhuyenMai));

    final ok = await ClaimVoucherApi.claimVoucher(
      username: _username!,
      maKhuyenMai: voucher.maKhuyenMai,
    );

    if (!mounted) return;

    if (ok) {
      _confettiCtrl.forward(from: 0);
      _showSuccessSnack(voucher);
      await _loadVouchers();
    } else {
      _showErrorSnack();
    }

    if (mounted) setState(() => _claiming.remove(voucher.maKhuyenMai));
  }

  void _showSuccessSnack(KhuyenMaiModel v) {
    final pct = (v.phanTramGiam * 100).toStringAsFixed(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã lấy voucher giảm $pct% thành công!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppColor.kCourtGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lấy voucher thất bại. Thử lại nhé!',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColor.kCourtGreen,
            onRefresh: _loadVouchers,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColor.kCourtGreen,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_vouchers.isEmpty)
                  SliverFillRemaining(child: _buildEmpty())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => VoucherCard(
                          voucher: _vouchers[i],
                          isClaiming:
                          _claiming.contains(_vouchers[i].maKhuyenMai),
                          onClaim: () => _claimVoucher(_vouchers[i]),
                          index: i,
                        ),
                        childCount: _vouchers.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => _confettiCtrl.value > 0
                ? ConfettiOverlay(progress: _confettiCtrl.value)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: 165,
      floating: false,
      pinned: true,
      backgroundColor: AppColor.kDeepGreen,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadVouchers,
          icon: _isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColor.kAccentYellow, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'SmashZone',
                      style: TextStyle(
                        color: AppColor.kAccentYellow,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_vouchers.length} voucher',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Text(
                  'Kho Voucher',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Những ưu đãi đang chờ bạn săn 🔥',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: const Text(
        'Kho Voucher',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColor.kMintField,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded,
                color: AppColor.kCourtGreen, size: 38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hết voucher rồi!',
            style: TextStyle(
              color: AppColor.kTextDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn đã sở hữu tất cả voucher hiện có 🎉',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}