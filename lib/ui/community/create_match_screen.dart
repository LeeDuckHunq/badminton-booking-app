import 'package:application/api/community_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/community/match_form.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// Mở trận từ một lượt đặt sân của mình. Trả về trận vừa tạo qua Navigator.pop.
class CreateMatchScreen extends StatefulWidget {
  final String? bookingId;
  final String? groupId;
  const CreateMatchScreen({super.key, this.bookingId, this.groupId});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _draft = MatchDraft();
  List<MatchBooking>? _bookings;
  List<GroupInfo> _groups = [];
  Map<String, String> _images = {};
  Object? _error;
  String? _booking;
  late String? _group = widget.groupId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.bookingId;
    if (_group != null) _draft.congKhai = false;
    _draft.loadSavedBank().then((_) { if (mounted) setState(() {}); });
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await Future.wait([CommunityApi.bookings(), CommunityApi.myGroups().catchError((_) => <GroupInfo>[]), HinhAnhSanApi.getAllHinhAnhSan().catchError((_) => <String, String>{})]);
      if (!mounted) return;
      final bookings = r[0] as List<MatchBooking>;
      setState(() {
        _bookings = bookings;
        _groups = (r[1] as List<GroupInfo>).where((g) => g.isMember && !g.khoa).toList();
        _images = r[2] as Map<String, String>;
        if (bookings.isNotEmpty && !bookings.any((b) => b.maPhieuDat == _booking)) _booking = bookings.first.maPhieuDat;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  MatchBooking? get _chosen => _bookings?.where((b) => b.maPhieuDat == _booking).firstOrNull;

  Future<void> _submit() async {
    final b = _chosen;
    if (b == null) return;
    setState(() => _busy = true);
    try {
      final m = await CommunityApi.create({..._draft.toJson(), 'maPhieuDat': b.maPhieuDat, 'maNhom': _group, 'congKhai': _group == null ? true : _draft.congKhai});
      await _draft.saveBank();
      if (!mounted) return;
      showSzSnack(context, 'Đã mở trận! Chia sẻ để rủ thêm người nhé');
      Navigator.pop(context, m);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _chosen;
    return Scaffold(
      backgroundColor: AppColor.canvas,
      appBar: const SzTopBar(title: 'Mở trận mới', subtitle: 'Rủ thêm người chơi cho sân đã đặt'),
      bottomNavigationBar: _bookings == null || _bookings!.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mỗi người góp', style: AppText.bodySm()),
                      Text(Fmt.money(int.tryParse(_draft.fee.text) ?? _draft.suggestedFee(b?.tongTien ?? 0)), style: AppText.stat(size: 20, color: AppColor.primaryDark)),
                    ]),
                  ),
                  SzButton('Mở trận', icon: Icons.rocket_launch_rounded, loading: _busy, onPressed: b == null ? null : _submit),
                ]),
              ),
            ),
      body: _error != null
          ? SzErrorState(message: '$_error', onRetry: _load)
          : _bookings == null
              ? const SzLoading()
              : _bookings!.isEmpty
                  ? SzEmptyState(icon: Icons.event_available_rounded, title: 'Bạn chưa có lượt đặt sân sắp tới', message: 'Trận được mở từ một lượt đặt sân của bạn (chờ duyệt hoặc đã xác nhận). Đặt sân trước rồi quay lại nhé!', actionLabel: 'Quay lại', onAction: () => Navigator.pop(context))
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
                      _step(1, 'Chọn lượt đặt sân'),
                      for (final bk in _bookings!) _bookingTile(bk),
                      const SizedBox(height: 14),
                      _step(2, 'Trận của ai?'),
                      _ownerTile(null, Icons.person_rounded, 'Trận cá nhân', 'Công khai, ai cũng có thể xin vào'),
                      for (final g in _groups) _ownerTile(g.maNhom, null, g.tenNhom, '${g.soThanhVien} thành viên vào thẳng, không cần duyệt', group: g),
                      const SizedBox(height: 14),
                      _step(3, 'Luật chơi & chia tiền'),
                      SzCard(child: MatchFields(key: ValueKey(_group == null), draft: _draft, courtPrice: b?.tongTien ?? 0, hasGroup: _group != null, onChanged: () => setState(() {}))),
                    ]),
    );
  }

  Widget _step(int n, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: AppColor.primaryDark, borderRadius: BorderRadius.circular(9)), child: Text('$n', style: AppText.labelLg(color: Colors.white))),
          const SizedBox(width: 10),
          Text(title, style: AppText.headlineSm().copyWith(fontSize: 17)),
        ]),
      );

  Widget _selectable({required bool selected, required VoidCallback onTap, required Widget child}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF4FBF6) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? AppColor.primary : AppColor.border, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [Expanded(child: child), AnimatedScale(scale: selected ? 1 : 0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack, child: const Icon(Icons.check_circle_rounded, color: AppColor.primary))])),
            ),
          ),
        ),
      );

  Widget _bookingTile(MatchBooking bk) {
    final image = bk.maCumSan == null ? null : _images[bk.maCumSan];
    return _selectable(
      selected: _booking == bk.maPhieuDat,
      onTap: () => setState(() => _booking = bk.maPhieuDat),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(width: 64, height: 64, child: image == null ? Container(color: AppColor.mint, child: const Icon(Icons.sports_tennis_rounded, color: AppColor.primary)) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColor.mint))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bk.tenCumSan, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.labelLg()),
            Text('${bk.tenSan} · ${Fmt.money(bk.tongTien)}', style: AppText.bodySm()),
            const SizedBox(height: 2),
            Text('${Fmt.dateShort(bk.batDau)} · ${Fmt.range(bk.batDau, bk.ketThuc)}', style: AppText.label()),
            if (bk.trangThai == 'CHO_XAC_NHAN') Text('Chờ chủ sân duyệt', style: AppText.label(color: const Color(0xFFB45309))),
          ]),
        ),
      ]),
    );
  }

  Widget _ownerTile(String? id, IconData? icon, String title, String subtitle, {GroupInfo? group}) => _selectable(
        selected: _group == id,
        onTap: () => setState(() {
          _group = id;
          _draft.congKhai = id == null;
        }),
        child: Row(children: [
          if (group != null)
            GroupAvatar(name: group.tenNhom, mau: group.mau, size: 42)
          else
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColor.primaryDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppText.labelLg()), Text(subtitle, style: AppText.bodySm())])),
        ]),
      );
}
