import 'package:application/api/community_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/api/payment_proof_api.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/community/group_detail_screen.dart';
import 'package:application/ui/community/match_form.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  MatchInfo? _m;
  Object? _error;
  String _me = '';
  String? _image;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = await CommunityApi.match(widget.matchId);
      final images = await HinhAnhSanApi.getAllHinhAnhSan().catchError((_) => <String, String>{});
      if (!mounted) return;
      setState(() {
        _me = prefs.getString('username') ?? '';
        _m = m;
        _image = images[m.maCumSan];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _act(String key, Future<MatchInfo> Function() fn, [String? message]) async {
    setState(() => _busy = key);
    try {
      final m = await fn();
      if (!mounted) return;
      setState(() => _m = m);
      if (message != null) showSzSnack(context, message);
    } catch (e) {
      if (mounted) {
        showCommunityError(context, e);
        _load();
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _share() {
    final m = _m!;
    Clipboard.setData(ClipboardData(text: '${m.tieuDe} – ${Fmt.dateLong(m.batDau)} ${Fmt.range(m.batDau, m.ketThuc)} tại ${m.tenCumSan}\n$kWebBase/tran/${m.maTran}'));
    showSzSnack(context, 'Đã sao chép link trận, dán vào Zalo / Messenger để rủ bạn nhé', type: SzToast.info);
  }

  Future<void> _askJoin() async {
    final result = await showModalBottomSheet<(String?, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: _JoinSheet(group: _m!.tenNhom)),
    );
    if (result == null) return;
    await _act('join', () => CommunityApi.join(_m!.maTran, trinhDo: result.$1, loiNhan: result.$2), 'Đã gửi yêu cầu, chờ chủ trận duyệt nhé');
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<MatchInfo>(context, MaterialPageRoute(builder: (_) => _EditMatchScreen(match: _m!)));
    if (updated != null && mounted) setState(() => _m = updated);
  }

  Future<void> _confirm(String key, {required String title, required String message, required String label, required Future<MatchInfo> Function() fn, required String done, IconData icon = Icons.help_outline_rounded}) async {
    final ok = await showSzConfirm(context, title: title, message: message, confirmLabel: label, cancelLabel: 'Không', icon: icon, destructive: true);
    if (ok) await _act(key, fn, done);
  }

  void _chatHost() {
    final m = _m!;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(currentUsername: _me, peer: ChatUser(username: m.chuTran.username, fullName: m.chuTran.ten))));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: const SzTopBar(title: 'Trận'), body: SzErrorState(message: '$_error', onRetry: _load));
    final m = _m;
    if (m == null) return const Scaffold(appBar: SzTopBar(title: 'Trận'), body: SzLoading());
    final host = m.toi?.laChuTran == true;
    final going = m.thanhVien.where((p) => p.trangThai == 'THAM_GIA').toList();
    final waiting = m.thanhVien.where((p) => p.trangThai == 'CHO').toList();
    final requests = m.thanhVien.where((p) => p.trangThai == 'CHO_DUYET').toList();
    final others = m.thanhVien.where((p) => p.trangThai == 'VANG' || p.trangThai == 'TU_CHOI').toList();
    final iAmGoing = m.toi?.trangThai == 'THAM_GIA';

    return Scaffold(
      backgroundColor: AppColor.canvas,
      bottomNavigationBar: _actionBar(m, host),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColor.forest,
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.share_rounded), tooltip: 'Chia sẻ', onPressed: _share),
              if (host && m.upcoming)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'cancel') {
                      _confirm('cancel', title: 'Huỷ trận này?', message: 'Mọi người sẽ thấy trận đã huỷ. Lượt đặt sân của bạn vẫn giữ nguyên.', label: 'Huỷ trận', icon: Icons.event_busy_rounded, fn: () => CommunityApi.cancel(m.maTran), done: 'Đã huỷ trận');
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'cancel', child: Text('Huỷ trận'))],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                if (_image != null) Image.network(_image!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColor.forest)) else Container(color: AppColor.forest),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x66081E10), Color(0x22081E10), Color(0xE6081E10)]))),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        StatusTag(matchStatus(m.trangThai)),
                        _glass(playTypeLabel(m.kieuChoi)),
                        _glass(levelRange(m.trinhDoTu, m.trinhDoDen)),
                      ]),
                      const SizedBox(height: 8),
                      Text(m.tieuDe, style: AppText.headlineLg(color: Colors.white).copyWith(fontSize: 24)),
                      const SizedBox(height: 6),
                      _heroLine(Icons.calendar_today_rounded, '${Fmt.dateLong(m.batDau)} · ${Fmt.range(m.batDau, m.ketThuc)}'),
                      _heroLine(Icons.location_on_outlined, '${m.tenCumSan} · ${m.tenSan}'),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList.list(children: [
              SzCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: _stat('Mỗi người góp', m.chiPhiMoiNguoi > 0 ? Fmt.money(m.chiPhiMoiNguoi) : 'Miễn phí')),
                      const SizedBox(width: 10),
                      Expanded(child: _stat('Người chơi', '${m.soDaThamGia}/${m.soNguoiToiDa}', extra: SlotMeter(total: m.soNguoiToiDa, filled: m.soDaThamGia))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    SzAvatar(m.chuTran.ten, size: 34),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chủ trận', style: AppText.bodySm()), Text(m.chuTran.ten, style: AppText.labelLg())])),
                    if (!host) SzButton.small('Nhắn tin', icon: Icons.chat_bubble_outline_rounded, kind: SzButtonKind.soft, onPressed: _chatHost),
                  ]),
                  if (m.ghiChu != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFFFFBEA), border: Border(left: BorderSide(color: AppColor.accent, width: 4)), borderRadius: BorderRadius.horizontal(right: Radius.circular(12))),
                      child: Text(m.ghiChu!, style: AppText.body()),
                    ),
                  ],
                  if (m.maNhom != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: m.maNhom!))),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: AppColor.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Row(children: [
                          GroupAvatar(name: m.tenNhom ?? 'Nhóm', mau: m.mauNhom, size: 34),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Trận của nhóm', style: AppText.bodySm()), Text(m.tenNhom ?? '', style: AppText.labelLg())])),
                          if (!m.congKhai) const SzPill('Chỉ thành viên', bg: AppColor.slot, fg: AppColor.textMuted),
                          const Icon(Icons.chevron_right_rounded, color: AppColor.textSubtle),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SzButton.small('Chỉ đường tới sân', icon: Icons.near_me_outlined, kind: SzButtonKind.soft, expand: true, onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(m.diaChi ?? m.tenCumSan)}'), mode: LaunchMode.externalApplication)),
                ]),
              ),
              if (_stateNote(m, host) != null) ...[const SizedBox(height: 12), _stateNote(m, host)!],
              if (!host && iAmGoing) ...[const SizedBox(height: 12), _PayCard(m: m, me: _me, onDone: (u) => setState(() => _m = u))],
              if (host) ...[const SizedBox(height: 12), _moneyCard(m)],
              if (host && requests.isNotEmpty) ...[
                const SizedBox(height: 12),
                SzCard(
                  border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SzSectionTitle(Icons.person_add_alt_1_rounded, 'Yêu cầu tham gia', trailing: SzPill('${requests.length}', bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309))),
                    const SizedBox(height: 10),
                    for (final p in requests) _player(m, p, host),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              SzCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SzSectionTitle(Icons.groups_rounded, 'Danh sách chơi', trailing: SzPill('${going.length}/${m.soNguoiToiDa}')),
                  const SizedBox(height: 10),
                  for (final p in going) _player(m, p, host),
                  for (var i = going.length; i < m.soNguoiToiDa; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD6EBDD), width: 1.5), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [
                        Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9E3C6), width: 1.5))),
                        const SizedBox(width: 10),
                        Text('Còn trống', style: AppText.body(color: AppColor.textMuted)),
                      ]),
                    ),
                  if (waiting.isNotEmpty) ...[_label('DANH SÁCH CHỜ'), for (final p in waiting) _player(m, p, host)],
                  if (others.isNotEmpty) ...[_label('VẮNG / KHÔNG THAM GIA'), for (final p in others) Opacity(opacity: 0.6, child: _player(m, p, host))],
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _glass(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
        child: Text(text, style: AppText.label(color: Colors.white).copyWith(fontSize: 11.5)),
      );

  Widget _heroLine(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [Icon(icon, size: 15, color: Colors.white70), const SizedBox(width: 6), Expanded(child: Text(text, style: AppText.body(color: Colors.white)))]),
      );

  Widget _stat(String label, String value, {Widget? extra}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.bodySm()),
          const SizedBox(height: 4),
          Text(value, style: AppText.stat(size: 19)),
          if (extra != null) ...[const SizedBox(height: 6), extra],
        ]),
      );

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 8), child: Text(text, style: AppText.labelSm(color: AppColor.textSubtle)));

  Widget? _stateNote(MatchInfo m, bool host) {
    final st = m.toi?.trangThai;
    final (String, Color, Color, IconData)? note = host
        ? null
        : switch (st) {
            'CHO' => ('Bạn đang ở danh sách chờ. Có người rời là bạn tự vào.', const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.hourglass_top_rounded),
            'CHO_DUYET' => ('Đã gửi yêu cầu. Chủ trận sẽ duyệt sớm!', const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.hourglass_top_rounded),
            'TU_CHOI' => ('Chủ trận chưa thể nhận bạn ở trận này. Thử tìm trận khác nhé!', AppColor.slot, const Color(0xFF374151), Icons.info_outline_rounded),
            'VANG' => ('Bạn đã báo vắng trận này.', AppColor.slot, const Color(0xFF374151), Icons.info_outline_rounded),
            _ => null,
          };
    if (note == null) return null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: note.$2, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [Icon(note.$4, color: note.$3, size: 20), const SizedBox(width: 8), Expanded(child: Text(note.$1, style: AppText.labelLg(color: note.$3)))]),
    );
  }

  Widget? _actionBar(MatchInfo m, bool host) {
    Widget? content;
    final st = m.toi?.trangThai;
    if (host) {
      content = Row(children: [
        if (m.upcoming) ...[Expanded(child: SzButton('Sửa trận', icon: Icons.edit_outlined, kind: SzButtonKind.soft, onPressed: _edit)), const SizedBox(width: 10)],
        Expanded(child: SzButton('Rủ thêm người', icon: Icons.share_rounded, onPressed: _share)),
      ]);
    } else if (!m.upcoming) {
      return null;
    } else if (st == 'THAM_GIA' || st == 'CHO') {
      content = SzButton(st == 'CHO' ? 'Rời danh sách chờ' : 'Rời trận', icon: Icons.logout_rounded, kind: SzButtonKind.dangerSoft, expand: true, loading: _busy == 'leave',
          onPressed: () => _confirm('leave', title: 'Rời trận?', message: 'Nếu đã chuyển tiền, hãy nhắn chủ trận để được hoàn lại.', label: 'Rời trận', icon: Icons.logout_rounded, fn: () => CommunityApi.leave(m.maTran), done: 'Bạn đã rời trận'));
    } else if (st == 'CHO_DUYET') {
      content = SzButton('Huỷ yêu cầu', kind: SzButtonKind.outline, expand: true, loading: _busy == 'leave', onPressed: () => _act('leave', () => CommunityApi.leave(m.maTran), 'Đã huỷ yêu cầu'));
    } else if (st == 'TU_CHOI') {
      return null;
    } else if (m.toi?.laThanhVienNhom == true) {
      content = Row(children: [
        if (st != 'VANG') ...[Expanded(child: SzButton('Báo vắng', kind: SzButtonKind.soft, loading: _busy == 'leave', onPressed: () => _act('leave', () => CommunityApi.leave(m.maTran), 'Đã báo vắng'))), const SizedBox(width: 10)],
        Expanded(flex: 2, child: SzButton(m.trangThai == 'DU_NGUOI' ? 'Vào danh sách chờ' : 'Tham gia', icon: Icons.check_rounded, loading: _busy == 'join', onPressed: () => _act('join', () => CommunityApi.join(m.maTran), 'Đã điểm danh tham gia!'))),
      ]);
    } else if (m.trangThai == 'DU_NGUOI') {
      content = const SzButton('Trận đã đủ người', expand: true, onPressed: null);
    } else {
      content = SzButton('Xin vào trận', icon: Icons.person_add_alt_1_rounded, expand: true, loading: _busy == 'join', onPressed: _askJoin);
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
        child: content,
      ),
    );
  }

  Widget _moneyCard(MatchInfo m) {
    final ratio = (m.canThu ?? 0) == 0 ? 0.0 : ((m.daThu ?? 0) / m.canThu!).clamp(0.0, 1.0);
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SzSectionTitle(Icons.account_balance_wallet_outlined, 'Thu tiền'),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: v, minHeight: 10, backgroundColor: AppColor.slot, color: AppColor.primary)),
        ),
        const SizedBox(height: 6),
        SzInfoRow('Đã thu', Fmt.money(m.daThu ?? 0), strong: true, valueColor: AppColor.primaryDark),
        SzInfoRow('Cần thu', Fmt.money(m.canThu ?? 0)),
        if (m.tienSan != null) SzInfoRow('Tiền sân', Fmt.money(m.tienSan!)),
        Text(m.nhanTien == null ? 'Chưa thêm tài khoản nhận tiền. Bấm Sửa trận để thêm.' : 'Nhận qua ${bankName(m.nhanTien!.nganHang)} · ${m.nhanTien!.soTaiKhoan}', style: AppText.bodySm()),
      ]),
    );
  }

  Widget _player(MatchInfo m, MatchPlayer p, bool host) {
    final pay = payStatus(p.thanhToan);
    final upcoming = m.upcoming;
    final actions = <Widget>[
      if (host && p.billUrl != null) SzIconButton(Icons.receipt_long_rounded, size: 36, background: AppColor.mint, color: AppColor.primaryDark, tooltip: 'Xem bill', onPressed: () => _showBill(p)),
      if (host && p.trangThai == 'CHO_DUYET' && upcoming) ...[
        SzIconButton(Icons.close_rounded, size: 36, background: AppColor.slot, color: AppColor.textMuted, tooltip: 'Từ chối', onPressed: () => _act('r${p.username}', () => CommunityApi.review(m.maTran, p.username, false), 'Đã từ chối')),
        const SizedBox(width: 4),
        SzButton.small('Duyệt', icon: Icons.check_rounded, loading: _busy == 'a${p.username}', onPressed: () => _act('a${p.username}', () => CommunityApi.review(m.maTran, p.username, true), 'Đã nhận ${p.ten} vào trận')),
      ],
      if (host && !p.laChuTran && (p.trangThai == 'THAM_GIA' || p.trangThai == 'VANG') && p.thanhToan != null && p.thanhToan != 'MIEN')
        p.thanhToan == 'DA_TRA'
            ? SzButton.small('Bỏ xác nhận', kind: SzButtonKind.ghost, onPressed: () => _act('p${p.username}', () => CommunityApi.confirmPaid(m.maTran, p.username, false)))
            : SzButton.small('Đã nhận', icon: Icons.payments_outlined, kind: p.thanhToan == 'CHO_XAC_NHAN' ? SzButtonKind.primary : SzButtonKind.soft, loading: _busy == 'p${p.username}', onPressed: () => _act('p${p.username}', () => CommunityApi.confirmPaid(m.maTran, p.username, true), 'Đã ghi nhận tiền')),
      if (host && !p.laChuTran && (p.trangThai == 'THAM_GIA' || p.trangThai == 'CHO') && upcoming)
        SzIconButton(Icons.person_remove_outlined, size: 36, color: AppColor.danger, tooltip: 'Mời ra',
            onPressed: () => _confirm('k${p.username}', title: 'Mời ${p.ten} ra khỏi trận?', message: 'Người này sẽ không thể xin vào lại trận.', label: 'Mời ra', icon: Icons.person_remove_outlined, fn: () => CommunityApi.kick(m.maTran, p.username), done: 'Đã mời ra khỏi trận')),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          p.laChuTran ? SzAvatar(p.ten, size: 38) : SzAvatar.soft(p.ten, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.username == _me ? '${p.ten} (bạn)' : p.ten, style: AppText.labelLg()),
              const SizedBox(height: 3),
              Wrap(spacing: 5, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (p.laChuTran) const SzPill('Chủ trận', icon: Icons.workspace_premium_rounded, bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
                if (!p.laChuTran && p.trangThai == 'CHO_DUYET') const SzPill('Chờ duyệt', bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
                if (!p.laChuTran && p.trangThai == 'CHO') const SzPill('Danh sách chờ', bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
                if (p.trangThai == 'VANG') const SzPill('Vắng', bg: AppColor.slot, fg: AppColor.textMuted),
                if (p.trangThai == 'TU_CHOI') const SzPill('Bị từ chối', bg: AppColor.slot, fg: AppColor.textMuted),
                if (p.trinhDo != null) SzPill(levelLabel(p.trinhDo), bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1D4ED8)),
                if (!p.laChuTran && p.trangThai == 'THAM_GIA' && p.thanhToan != null) SzPill(pay.$1, bg: pay.$2, fg: pay.$3),
                if (p.soTranDaChoi != null) Text('${p.soTranDaChoi} trận đã chơi', style: AppText.bodySm()),
              ]),
            ]),
          ),
        ]),
        if (p.loiNhan != null) Padding(padding: const EdgeInsets.only(top: 6, left: 48), child: Text('“${p.loiNhan}”', style: AppText.body(color: const Color(0xFF4B5563)).copyWith(fontStyle: FontStyle.italic))),
        if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [for (final a in actions) Padding(padding: const EdgeInsets.only(left: 6), child: a)])),
      ]),
    );
  }

  void _showBill(MatchPlayer p) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(14), child: Text('Bill của ${p.ten} · ${Fmt.money(p.soTien)}', style: AppText.headlineSm())),
          Flexible(child: InteractiveViewer(child: Image.network(p.billUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Padding(padding: EdgeInsets.all(24), child: Text('Không tải được ảnh'))))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ]),
      ),
    );
  }
}

/// Thẻ góp tiền: QR VietQR + báo đã chuyển kèm bill.
class _PayCard extends StatefulWidget {
  final MatchInfo m;
  final String me;
  final ValueChanged<MatchInfo> onDone;
  const _PayCard({required this.m, required this.me, required this.onDone});

  @override
  State<_PayCard> createState() => _PayCardState();
}

class _PayCardState extends State<_PayCard> {
  Uint8List? _bytes;
  String? _name;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() { _bytes = bytes; _name = picked.name; });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      String? url;
      if (_bytes != null) {
        url = await PaymentProofApi.upload(bytes: _bytes!, filename: _name ?? 'bill.jpg');
        if (url == null) throw const CommunityException('Không tải được ảnh bill, thử lại nhé');
      }
      final m = await CommunityApi.pay(widget.m.maTran, url);
      widget.onDone(m);
      if (mounted) {
        setState(() => _bytes = null);
        showSzSnack(context, 'Đã báo chủ trận. Chờ xác nhận nhé!');
      }
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    showSzSnack(context, message, type: SzToast.info);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final mine = m.thanhVien.where((p) => p.username == widget.me).firstOrNull;
    final amount = mine?.soTien ?? m.chiPhiMoiNguoi;
    final status = mine?.thanhToan;
    final pay = payStatus(status);
    final note = transferNote(m.maTran, widget.me);
    final qr = m.nhanTien == null ? null : vietQrUrl(m.nhanTien!, amount, note);
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SzSectionTitle(Icons.account_balance_wallet_outlined, 'Góp tiền sân'),
        const SizedBox(height: 12),
        if (amount == 0)
          _ok('Trận này không cần góp tiền')
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              Text('Phần của bạn', style: AppText.bodySm()),
              const SizedBox(width: 8),
              Expanded(child: Text(Fmt.money(amount), style: AppText.stat(size: 22, color: AppColor.primaryDark))),
              StatusTag(pay),
            ]),
          ),
          const SizedBox(height: 12),
          if (status == 'DA_TRA')
            _ok('Chủ trận đã xác nhận bạn trả tiền. Hẹn gặp ở sân!')
          else ...[
            if (m.nhanTien != null) ...[
              if (qr != null)
                Center(
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.border), boxShadow: AppShadow.card, color: Colors.white),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(qr, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(height: 80, child: Center(child: Text('Không tải được mã QR')))),
                  ),
                ),
              const SizedBox(height: 8),
              SzInfoRow('Ngân hàng', bankName(m.nhanTien!.nganHang)),
              SzInfoRow('Số tài khoản', m.nhanTien!.soTaiKhoan, trailing: InkWell(onTap: () => _copy(m.nhanTien!.soTaiKhoan, 'Đã sao chép số tài khoản'), child: const Icon(Icons.copy_rounded, size: 18, color: AppColor.primary))),
              if (m.nhanTien!.chuTaiKhoan != null) SzInfoRow('Chủ tài khoản', m.nhanTien!.chuTaiKhoan!),
              SzInfoRow('Nội dung', note, trailing: InkWell(onTap: () => _copy(note, 'Đã sao chép nội dung chuyển khoản'), child: const Icon(Icons.copy_rounded, size: 18, color: AppColor.primary))),
            ] else
              Text('Chủ trận chưa thêm tài khoản nhận tiền, có thể trả tiền mặt tại sân.', style: AppText.body(color: AppColor.textMuted)),
            const SizedBox(height: 10),
            if (_bytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: Image.memory(_bytes!, height: 140, width: double.infinity, fit: BoxFit.cover)),
              ),
            Row(children: [
              Expanded(child: SzButton.small(_bytes == null ? (mine?.billUrl != null ? 'Đổi ảnh bill' : 'Đính kèm bill') : 'Chọn ảnh khác', icon: Icons.add_photo_alternate_outlined, kind: SzButtonKind.soft, expand: true, onPressed: _pick)),
              const SizedBox(width: 8),
              Expanded(child: SzButton.small(status == 'CHO_XAC_NHAN' ? 'Gửi lại' : 'Tôi đã chuyển', icon: Icons.payments_outlined, expand: true, loading: _busy, onPressed: _submit)),
            ]),
            if (status == 'CHO_XAC_NHAN') Padding(padding: const EdgeInsets.only(top: 8), child: Text('Đã báo chủ trận, đang chờ xác nhận.', style: AppText.bodySm(color: const Color(0xFFB45309)))),
          ],
        ],
      ]),
    );
  }

  Widget _ok(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(children: [const Icon(Icons.check_circle_rounded, color: AppColor.primary), const SizedBox(width: 8), Expanded(child: Text(text, style: AppText.labelLg(color: AppColor.primaryDark)))]),
      );
}

class _JoinSheet extends StatefulWidget {
  final String? group;
  const _JoinSheet({this.group});

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  String? _level;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SzSheetHandle(),
          const SzSheetHeader(title: 'Xin vào trận', subtitle: 'Chủ trận xem lời nhắn và trình độ của bạn trước khi duyệt', icon: Icons.person_add_alt_1_rounded),
          if (widget.group != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Bạn chưa ở trong nhóm ${widget.group}, nên cần chủ trận duyệt.', style: AppText.bodySm())),
          fieldLabel('Trình độ của bạn'),
          LevelDropdown(value: _level, allLabel: 'Không nói rõ', onChanged: (v) => setState(() => _level = v)),
          fieldLabel('Lời nhắn', hint: 'không bắt buộc'),
          TextField(controller: _note, maxLength: 300, maxLines: 3, decoration: szInputDecoration(hint: 'VD: Mình đánh đôi nam nữ được, sẽ đến sớm 10 phút')),
          const SizedBox(height: 10),
          SzButton('Gửi yêu cầu', icon: Icons.send_rounded, expand: true, onPressed: () => Navigator.pop(context, (_level, _note.text.trim()))),
        ]),
      ),
    );
  }
}

/// Sửa trận (chủ trận).
class _EditMatchScreen extends StatefulWidget {
  final MatchInfo match;
  const _EditMatchScreen({required this.match});

  @override
  State<_EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends State<_EditMatchScreen> {
  late final _draft = MatchDraft.fromMatch(widget.match);
  bool _busy = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final m = await CommunityApi.update(widget.match.maTran, _draft.toJson());
      await _draft.saveBank();
      if (!mounted) return;
      showSzSnack(context, 'Đã cập nhật trận');
      Navigator.pop(context, m);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.canvas,
      appBar: SzTopBar(title: 'Sửa trận', subtitle: widget.match.tieuDe),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
          child: SzButton('Lưu thay đổi', icon: Icons.check_rounded, expand: true, loading: _busy, onPressed: _save),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SzCard(child: MatchFields(draft: _draft, courtPrice: widget.match.tienSan ?? 0, hasGroup: widget.match.maNhom != null)),
      ]),
    );
  }
}
