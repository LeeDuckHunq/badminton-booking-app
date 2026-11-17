// lib/ui/screen/account_screen.dart
import 'package:application/api/account_api.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/api/khuyen_mai_api.dart';
import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/model/user_model.dart';
import 'package:application/security/AuthManager.dart';
import 'package:application/ui/account/screens/booking_history_screen.dart';
import 'package:application/ui/account/screens/voucher_screen.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M15 – Tài khoản (tab).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _user;
  List<PhieuDatSanModel> _phieuList = [];
  List<KhuyenMaiModel> _vouchers = [];
  Map<String, SanModel> _sanMap = {};
  Map<String, CumSanModel> _cumSanMap = {};
  Map<String, String> _images = {};
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username == null) throw Exception('missing username');

      final results = await Future.wait([
        AccountApi.getUser(username),
        PhieuDatSanApi.getPhieuDatSanTheoUser(username),
        KhuyenMaiApi.getKhuyenMaiTheoUser(username),
        HinhAnhSanApi.getAllHinhAnhSan(),
      ]);
      final phieuList = results[1] as List<PhieuDatSanModel>;

      // Tra cứu sân và cụm sân (mỗi mã chỉ gọi 1 lần, song song).
      final sanIds = phieuList.map((p) => p.maSan).toSet();
      final sans = await Future.wait(sanIds.map((id) => SanApi.getSanInfo(id).catchError((_) => null)));
      final sanMap = {for (final s in sans.whereType<SanModel>()) s.maSan: s};
      final venueIds = sanMap.values.map((s) => s.maCumSan).toSet();
      final venues = await Future.wait(venueIds.map((id) => CumSanApi.getCumSanInfo(id).catchError((_) => null)));

      if (!mounted) return;
      setState(() {
        _user = results[0] as UserModel;
        _phieuList = phieuList;
        _vouchers = results[2] as List<KhuyenMaiModel>;
        _images = results[3] as Map<String, String>;
        _sanMap = sanMap;
        _cumSanMap = {for (final v in venues.whereType<CumSanModel>()) v.maCumSan: v};
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load account error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) => _load());

  Future<void> _logout() async {
    final ok = await showSzConfirm(context, title: 'Đăng xuất?', message: 'Bạn có chắc muốn đăng xuất khỏi SmashZone?', confirmLabel: 'Đăng xuất', icon: Icons.logout_rounded, destructive: true);
    if (!ok || !mounted) return;
    await AuthManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showVersion() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SzLogo(size: 64),
            const SizedBox(height: 14),
            Text('SmashZone', style: AppText.headlineLg(color: AppColor.primaryDark)),
            Text('Đặt sân cầu lông nhanh chóng', style: AppText.body(color: AppColor.textMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(children: const [
                SzInfoRow('Phiên bản', 'v1.0.0'),
                SzInfoRow('Bản dựng', '1'),
                SzInfoRow('Môi trường', 'Production'),
              ]),
            ),
            const SizedBox(height: 12),
            SzButton('Đóng', expand: true, kind: SzButtonKind.soft, onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final confirmed = _phieuList.where((p) => p.trangThai == 'DA_XAC_NHAN').length;
    final pending = _phieuList.where((p) => p.trangThai == 'CHO_XAC_NHAN').length;
    final name = u == null ? '' : (u.fullName.isEmpty ? u.username : u.fullName);

    return Scaffold(
      body: Column(children: [
        SzBrandHeader(subtitle: 'Tài khoản', userName: name),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_loading && u == null) ...[
                  const SzSkeleton(height: 170, radius: AppRadius.lg),
                  const SizedBox(height: 14),
                  const SzSkeleton(height: 110, radius: AppRadius.lg),
                ] else if (_failed && u == null)
                  SzErrorState(message: 'Không tải được thông tin tài khoản.', onRetry: _load)
                else if (u != null) ...[
                  _profileCard(u, name),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _StatTile(icon: Icons.event_available_rounded, iconBg: const Color(0xFFB2F2BA), value: confirmed, label: 'Đã xác nhận', sub: 'Sắp tới', color: AppColor.primaryDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(icon: Icons.pending_actions_rounded, iconBg: const Color(0xFFFFE170), value: pending, label: 'Chờ xác nhận', sub: 'Chờ duyệt', color: AppColor.pending)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(icon: Icons.confirmation_number_outlined, iconBg: AppColor.mint, value: _vouchers.length, label: 'Voucher', sub: 'Khả dụng', color: AppColor.accentDeep)),
                  ]),
                ],
                const SizedBox(height: 14),
                SzCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    _MenuTile(
                      icon: Icons.sports_tennis_rounded,
                      label: 'Sân đã đặt',
                      badge: _phieuList.isEmpty ? null : SzPill('${_phieuList.length} phiếu'),
                      onTap: () => _push(BookingHistoryScreen(phieuList: _phieuList, sanMap: _sanMap, cumSanMap: _cumSanMap, images: _images)),
                    ),
                    _MenuTile(
                      icon: Icons.confirmation_number_outlined,
                      iconBg: const Color(0xFFFFE170),
                      iconColor: AppColor.text,
                      label: 'Voucher của tôi',
                      badge: _vouchers.isEmpty ? null : SzPill.accent('${_vouchers.length} voucher'),
                      onTap: () => _push(VoucherScreen(voucherList: _vouchers)),
                    ),
                    _MenuTile(icon: Icons.verified_user_outlined, label: 'Chính sách & Bảo mật', onTap: () => _push(const PolicyScreen())),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      iconBg: AppColor.canvas,
                      iconColor: AppColor.textMuted,
                      label: 'Phiên bản ứng dụng',
                      trailing: Text('v1.0.0', style: AppText.bodyLg(color: AppColor.textMuted)),
                      onTap: _showVersion,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SzButton('Đăng xuất', expand: true, height: 56, icon: Icons.logout_rounded, kind: SzButtonKind.dangerSoft, onPressed: _logout),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _profileCard(UserModel u, String name) {
    final roleLabel = switch (u.role) {
      'ROLE_ADMIN' => 'Quản trị viên',
      'ROLE_OWNER' => 'Chủ sân',
      _ => 'Thành viên SmashZone',
    };
    return SzCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          SzAvatar(name, size: 72, online: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppText.headlineMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('@${u.username}', style: AppText.body(color: AppColor.textMuted)),
              const SizedBox(height: 6),
              SzPill.accent(roleLabel, icon: Icons.workspace_premium_outlined),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _contact(Icons.phone_iphone_rounded, u.phoneNumber.isEmpty ? 'Chưa cập nhật số điện thoại' : u.phoneNumber),
            const SizedBox(height: 8),
            _contact(Icons.mail_outline_rounded, u.email.isEmpty ? 'Chưa cập nhật email' : u.email),
          ]),
        ),
      ]),
    );
  }

  Widget _contact(IconData icon, String text) => Row(children: [
        Icon(icon, size: 18, color: AppColor.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.body(), overflow: TextOverflow.ellipsis)),
      ]);
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final int value;
  final String label;
  final String sub;
  final Color color;

  const _StatTile({required this.icon, required this.iconBg, required this.value, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return SzCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, size: 18, color: AppColor.primaryDark)),
        const SizedBox(height: 6),
        Text('$value', style: AppText.stat(size: 26, color: color)),
        Text(label, style: AppText.label(), textAlign: TextAlign.center),
        Text(sub, style: AppText.bodySm()),
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, this.iconBg = AppColor.mint, this.iconColor = AppColor.primary, required this.label, this.badge, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.labelLg().copyWith(fontSize: 16))),
          if (badge != null) ...[badge!, const SizedBox(width: 8)],
          trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColor.textMuted),
        ]),
      ),
    );
  }
}
