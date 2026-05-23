// lib/ui/account/account_screen.dart

import 'package:application/api/account_api.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/khuyen_mai_api.dart';
import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/model/user_model.dart';
import 'package:application/security/AuthManager.dart';
import 'package:application/ui/account/screens/voucher_screen.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/screens/booking_history_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _user;
  List<PhieuDatSanModel> _phieuList = [];
  List<KhuyenMaiModel> _voucherList = [];
  List<SanModel> _sanList = [];
  List<CumSanModel> _cumSanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _phieuList.clear();
        _voucherList.clear();
        _sanList.clear();
        _cumSanList.clear();
      });

      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString("username");

      if (username == null) {
        throw Exception("Không tìm thấy username");
      }

      // Load data chính
      final user = await AccountApi.getUser(username);

      final phieuList =
      await PhieuDatSanApi.getPhieuDatSanTheoUser(username);

      final voucherList =
      await KhuyenMaiApi.getKhuyenMaiTheoUser(username);

      // Load sân + cụm sân
      List<SanModel> sanList = [];
      List<CumSanModel> cumSanList = [];

      for (var phieu in phieuList) {
        try {
          final san = await SanApi.getSanInfo(phieu.maSan);

          if (san != null) {
            sanList.add(san);

            final cumSan =
            await CumSanApi.getCumSanInfo(san.maCumSan);

            if (cumSan != null) {
              cumSanList.add(cumSan);
            }
          }
        } catch (e) {
          debugPrint("Load san/cumSan error: $e");
        }
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _phieuList = phieuList;
        _voucherList = voucherList;
        _sanList = sanList;
        _cumSanList = cumSanList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load account error: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6F4),
      child: RefreshIndicator(
        color: AppColor.kCourtGreen,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColor.kCourtGreen,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildUserCard(),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildMenuSection('Hoạt động', [
                      _MenuItem(
                        icon: Icons.sports_tennis_rounded,
                        label: 'Sân đã đặt',
                        badge: _phieuList.length.toString(),
                        color: AppColor.kCourtGreen,
                        onTap: () => _push(BookingHistoryScreen(
                          phieuList: _phieuList,
                          sanList: _sanList,
                          cumSanList: _cumSanList,
                        )),
                      ),
                      _MenuItem(
                        icon: Icons.local_offer_rounded,
                        label: 'Voucher của tôi',
                        badge: _voucherList
                            .where((v) => v.ngayKetThuc.isAfter(DateTime.now()))
                            .length
                            .toString(),
                        color: Colors.orange[700]!,
                        onTap: () =>
                            _push(VoucherScreen(voucherList: _voucherList)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuSection('Thông tin', [
                      _MenuItem(
                        icon: Icons.policy_outlined,
                        label: 'Chính sách & Bảo mật',
                        color: Colors.indigo,
                        onTap: () => _push(const PolicyScreen()),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Phiên bản ứng dụng',
                        color: Colors.blueGrey,
                        trailing: _versionBadge(),
                        onTap: () => _showVersionDialog(),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuSection('Tài khoản', [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Đăng xuất',
                        color: Colors.orange[700]!,
                        onTap: () => _showLogoutDialog(),
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 165,
      floating: false,
      pinned: true,
      backgroundColor: AppColor.kDeepGreen,
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _isLoading
              ? null
              : () async {
            await _loadData();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Cập nhật dữ liệu thành công!"
                ),
                backgroundColor: AppColor.kCourtGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          icon: _isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.kDeepGreen,
                AppColor.kCourtGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              topPadding + 16,
              20,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.sports_tennis_rounded,
                      color: AppColor.kAccentYellow,
                      size: 20,
                    ),
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
                    const Spacer()
                  ],
                ),
                const Text(
                  'Tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _user?.email ?? '',
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
        'Tài khoản',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }

  // ── User info card ────────────────────────────────────────────────────────
  Widget _buildUserCard() {
    if (_user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kCourtGreen.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/licensed-image?q=tbn:ANd9GcQjVuDVB12oj11fUHVG2fsgMKvglnd7eiANa4oR-6nZCbEZc_lajUm1iFn_Edl_0BwPwiDpfH_QefmCUNmvsPOUu4XlUJlcqg82LWyV3wdisFH-An2HNLLgVZ3sUpTbkyh2KfaPfgm_KCZf&s=19',
                ),
                onBackgroundImageError: (_, __) {},
                child: _user!.fullName.isNotEmpty ? null : const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user!.fullName,
                      style: const TextStyle(
                        color: AppColor.kTextDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      )),
                  const SizedBox(height: 3),
                  _infoChip(Icons.alternate_email_rounded, _user!.username),
                  const SizedBox(height: 3),
                  _infoChip(Icons.phone_outlined, _user!.phoneNumber),
                  const SizedBox(height: 3),
                  _infoChip(Icons.email_outlined, _user!.email),
                ],
              ),
            ),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.kMintField,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Text(
                _user!.role,
                style: const TextStyle(
                  color: AppColor.kCourtGreen,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final confirmed = _phieuList
        .where((p) => p.trangThai == 'DA_XAC_NHAN')
        .length;
    final pending = _phieuList
        .where((p) => p.trangThai == 'CHO_XAC_NHAN')
        .length;
    final activeVoucher = _voucherList
        .where((v) => v.ngayKetThuc.isAfter(DateTime.now()))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('$confirmed', 'Đã xác nhận', AppColor.kCourtGreen,
              Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _statCard('$pending', 'Chờ xác nhận', const Color(0xFFFF8F00),
              Icons.access_time_rounded),
          const SizedBox(width: 10),
          _statCard('$activeVoucher', 'Voucher', Colors.purple,
              Icons.local_offer_rounded),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                )),
            Text(label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Menu section ──────────────────────────────────────────────────────────
  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildMenuItem(item),
                    if (i < items.length - 1)
                      Divider(
                          height: 1,
                          indent: 56,
                          color: Colors.grey[100]),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    color: item.labelColor ?? AppColor.kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(item.badge!,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    )),
              )
            else if (item.trailing != null)
              item.trailing!
            else
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ── Version badge ─────────────────────────────────────────────────────────
  Widget _versionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.kMintField,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: const Text('v1.0.0',
          style: TextStyle(
            color: AppColor.kCourtGreen,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          )),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColor.kAccentYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_tennis_rounded,
                  color: AppColor.kDeepGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('SmashZone',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _versionRow('Phiên bản', '1.0.0'),
            _versionRow('Build', '2026051001'),
            _versionRow('Môi trường', 'Production'),
            _versionRow('Phát triển bởi', 'SmashZone Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng',
                style: TextStyle(
                    color: AppColor.kCourtGreen,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColor.kTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Huỷ',
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthManager.logout();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context,
                 MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Đăng xuất',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  void _push(Widget screen) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── MenuItem model ────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color? labelColor;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.labelColor,
    this.badge,
    this.trailing,
  });
}