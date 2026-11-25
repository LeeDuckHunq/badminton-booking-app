import 'package:application/api/community_api.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// Link web để chia sẻ trận / nhóm.
const String kWebBase = 'https://smashzone-web.lenguyenviethung412005.workers.dev';

const levels = [('YEU', 'Yếu'), ('TB_YEU', 'TB-'), ('TB', 'TB'), ('TB_KHA', 'TB+'), ('KHA', 'Khá'), ('GIOI', 'Giỏi')];
String levelLabel(String? code) => levels.firstWhere((l) => l.$1 == code, orElse: () => ('', code ?? '')).$2;

String levelRange(String? from, String? to) {
  if (from == null && to == null) return 'Mọi trình độ';
  if (from != null && to != null) return from == to ? levelLabel(from) : '${levelLabel(from)} – ${levelLabel(to)}';
  return from != null ? 'Từ ${levelLabel(from)}' : 'Đến ${levelLabel(to)}';
}

const playTypes = [('DOI', 'Đánh đôi', 4), ('DON', 'Đánh đơn', 2), ('GIAO_LUU', 'Giao lưu', 8)];
String playTypeLabel(String code) => playTypes.firstWhere((t) => t.$1 == code, orElse: () => ('', 'Giao lưu', 4)).$2;

/// (nhãn, nền, chữ)
(String, Color, Color) matchStatus(String code) => switch (code) {
      'MO' => ('Còn chỗ', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'DU_NGUOI' => ('Đủ người', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      'DANG_DIEN_RA' => ('Đang diễn ra', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'DA_KET_THUC' => ('Đã kết thúc', AppColor.slot, AppColor.textMuted),
      'DA_HUY' => ('Đã huỷ', AppColor.dangerSoft, AppColor.danger),
      _ => (code, AppColor.slot, AppColor.textMuted),
    };

(String, Color, Color) payStatus(String? code) => switch (code) {
      'CHO_XAC_NHAN' => ('Chờ xác nhận', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      'DA_TRA' => ('Đã trả', AppColor.mint, AppColor.primaryDark),
      'MIEN' => ('Chủ trận', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      _ => ('Chưa trả', AppColor.slot, AppColor.textMuted),
    };

String roleLabel(String role) => switch (role) { 'TRUONG_NHOM' => 'Trưởng nhóm', 'PHO_NHOM' => 'Phó nhóm', _ => 'Thành viên' };

const groupColors = [
  [Color(0xFF1A7A3C), Color(0xFF0F4D25)],
  [Color(0xFF2563EB), Color(0xFF1E3A8A)],
  [Color(0xFFD97706), Color(0xFF92400E)],
  [Color(0xFFDB2777), Color(0xFF831843)],
  [Color(0xFF0891B2), Color(0xFF164E63)],
  [Color(0xFF7C3AED), Color(0xFF4C1D95)],
];
LinearGradient groupGradient(int mau) => LinearGradient(colors: groupColors[mau % 6], begin: Alignment.topLeft, end: Alignment.bottomRight);

/// Ngân hàng hỗ trợ VietQR: (mã, tên, BIN).
const banks = [
  ('MB', 'MB Bank', '970422'), ('VCB', 'Vietcombank', '970436'), ('TCB', 'Techcombank', '970407'), ('ACB', 'ACB', '970416'),
  ('BIDV', 'BIDV', '970418'), ('ICB', 'VietinBank', '970415'), ('VPB', 'VPBank', '970432'), ('TPB', 'TPBank', '970423'),
  ('VIB', 'VIB', '970441'), ('STB', 'Sacombank', '970403'), ('VBA', 'Agribank', '970405'), ('HDB', 'HDBank', '970437'),
  ('MSB', 'MSB', '970426'), ('SHB', 'SHB', '970443'), ('OCB', 'OCB', '970448'),
];
String bankName(String code) => banks.firstWhere((b) => b.$1 == code, orElse: () => (code, code, '')).$2;

String? vietQrUrl(BankInfo bank, int amount, String info) {
  final bin = banks.firstWhere((b) => b.$1 == bank.nganHang, orElse: () => ('', '', '')).$3;
  if (bin.isEmpty) return null;
  final q = {'amount': '$amount', 'addInfo': info, if (bank.chuTaiKhoan != null) 'accountName': bank.chuTaiKhoan!};
  return Uri.https('img.vietqr.io', '/image/$bin-${bank.soTaiKhoan}-compact2.png', q).toString();
}

String transferNote(String maTran, String username) => 'SZ ${maTran.length > 10 ? maTran.substring(2, 10) : maTran} $username';

class GroupAvatar extends StatelessWidget {
  final String name;
  final int mau;
  final double size;
  const GroupAvatar({super.key, required this.name, this.mau = 0, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: groupGradient(mau),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [BoxShadow(color: groupColors[mau % 6][1].withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(Fmt.initials(name), style: AppText.headlineSm(color: Colors.white).copyWith(fontSize: size * 0.36)),
    );
  }
}

class StatusTag extends StatelessWidget {
  final (String, Color, Color) s;
  final IconData? icon;
  const StatusTag(this.s, {super.key, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: s.$2, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: s.$3), const SizedBox(width: 4)] else ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)), const SizedBox(width: 5)],
          Text(s.$1, style: AppText.label(color: s.$3).copyWith(fontSize: 11.5)),
        ]),
      );
}

/// Các chấm người chơi: chấm đặc = đã tham gia.
class SlotMeter extends StatelessWidget {
  final int total;
  final int filled;
  final double dot;
  const SlotMeter({super.key, required this.total, required this.filled, this.dot = 10});

  @override
  Widget build(BuildContext context) {
    final shown = total.clamp(0, 12);
    return Wrap(spacing: 3, runSpacing: 3, children: [
      for (var i = 0; i < shown; i++)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: i < filled ? AppColor.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: i < filled ? AppColor.primary : const Color(0xFFB9E3C6), width: 1.6),
            ),
          ),
        ),
    ]);
  }
}

/// Card trận dùng ở danh sách tìm trận / trận của tôi / trận của nhóm.
class MatchCard extends StatelessWidget {
  final MatchInfo m;
  final VoidCallback onTap;
  const MatchCard({super.key, required this.m, required this.onTap});

  String? get _rel {
    final now = DateTime.now();
    final diff = DateTime(m.batDau.year, m.batDau.month, m.batDau.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (diff) { 0 => 'Hôm nay', 1 => 'Ngày mai', 2 => 'Ngày kia', _ => null };
  }

  @override
  Widget build(BuildContext context) {
    final left = m.soNguoiToiDa - m.soDaThamGia;
    final mine = m.toi?.laChuTran == true
        ? ('Bạn là chủ trận', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8))
        : switch (m.toi?.trangThai) {
            'THAM_GIA' => ('Bạn đã tham gia', AppColor.mint, AppColor.primaryDark),
            'CHO' => ('Danh sách chờ', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
            'CHO_DUYET' => ('Đang chờ duyệt', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
            'TU_CHOI' => ('Không được duyệt', AppColor.slot, AppColor.textMuted),
            _ => null,
          };
    return Opacity(
      opacity: m.finished ? 0.7 : 1,
      child: SzCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColor.mint, Color(0xFFF4FBF6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border(right: BorderSide(color: Color(0xFFCFE9D7), width: 1.5)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_rel != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColor.accent, borderRadius: BorderRadius.circular(999)),
                    child: Text(_rel!, style: AppText.labelSm(color: AppColor.forest).copyWith(fontSize: 9.5)),
                  ),
                Text(Fmt.two(m.batDau.day), style: AppText.stat(size: 30)),
                Text('Th${m.batDau.month} · ${Fmt.weekdayShort(m.batDau)}', style: AppText.label(color: AppColor.primaryDark).copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text('${Fmt.hhmm(m.batDau)}\n${Fmt.hhmm(m.ketThuc)}', textAlign: TextAlign.center, style: AppText.label().copyWith(fontSize: 11, height: 1.25)),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    StatusTag(matchStatus(m.trangThai)),
                    if (m.tenNhom != null) ...[
                      const SizedBox(width: 6),
                      GroupAvatar(name: m.tenNhom!, mau: m.mauNhom, size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text(m.tenNhom!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label(color: AppColor.textMuted))),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Text(m.tieuDe, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.headlineSm()),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColor.textMuted),
                    const SizedBox(width: 3),
                    Expanded(child: Text('${m.tenCumSan} · ${m.tenSan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySm())),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    SzPill(playTypeLabel(m.kieuChoi)),
                    SzPill(levelRange(m.trinhDoTu, m.trinhDoDen), bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1D4ED8)),
                    if (!m.congKhai) const SzPill('Trong nhóm', icon: Icons.lock_outline_rounded, bg: AppColor.slot, fg: AppColor.textMuted),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    SzAvatar.soft(m.chuTran.ten, size: 24),
                    const SizedBox(width: 6),
                    Expanded(child: Text(m.chuTran.ten, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label(color: AppColor.textMuted))),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      SlotMeter(total: m.soNguoiToiDa, filled: m.soDaThamGia, dot: 8),
                      const SizedBox(height: 2),
                      Text(m.trangThai == 'MO' ? 'Còn $left chỗ' : '${m.soDaThamGia}/${m.soNguoiToiDa}', style: AppText.label(color: AppColor.primaryDark).copyWith(fontSize: 11)),
                    ]),
                  ]),
                  const Divider(height: 18, color: AppColor.slot),
                  Row(children: [
                    if (mine != null) StatusTag(mine, icon: Icons.person_rounded) else const SizedBox.shrink(),
                    const Spacer(),
                    Text(m.chiPhiMoiNguoi > 0 ? Fmt.money(m.chiPhiMoiNguoi) : 'Miễn phí', style: AppText.headlineSm(color: AppColor.primaryDark)),
                    if (m.chiPhiMoiNguoi > 0) Text('/người', style: AppText.bodySm()),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final GroupInfo g;
  final VoidCallback onTap;
  const GroupCard({super.key, required this.g, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SzCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupAvatar(name: g.tenNhom, mau: g.mau, size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g.tenNhom, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.headlineSm())),
              Icon(g.congKhai ? Icons.public_rounded : Icons.lock_outline_rounded, size: 15, color: AppColor.textSubtle),
            ]),
            const SizedBox(height: 2),
            Text('${g.khuVuc ?? 'Chưa đặt khu vực'} · ${g.soThanhVien} thành viên', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySm()),
            if ((g.tinNhanCuoi ?? g.moTa) != null) ...[
              const SizedBox(height: 6),
              Text(g.tinNhanCuoi ?? g.moTa!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(color: const Color(0xFF4B5563))),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              SzPill(g.trinhDo == null ? 'Mọi trình độ' : 'Trình ${levelLabel(g.trinhDo)}', bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1D4ED8)),
              if (g.isMember) SzPill(roleLabel(g.vaiTro ?? ''), icon: g.isOwner ? Icons.workspace_premium_rounded : null, bg: g.isOwner ? const Color(0xFFFEF3C7) : AppColor.mint, fg: g.isOwner ? const Color(0xFFB45309) : AppColor.primaryDark),
              if (g.isPending) const SzPill('Đang chờ duyệt', bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
              if (g.khoa) const SzPill('Đã bị khoá', icon: Icons.shield_outlined, bg: AppColor.dangerSoft, fg: AppColor.danger),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Thanh chọn kiểu "segmented" có nền trượt.
class SzSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const SzSegmented({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [
        for (final (v, label) in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: v == value ? AppShadow.card : null,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.labelLg(color: v == value ? AppColor.primaryDark : AppColor.textMuted).copyWith(fontSize: 13)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Ô chọn trình độ dạng dropdown.
class LevelDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String allLabel;
  const LevelDropdown({super.key, required this.value, required this.onChanged, this.allLabel = 'Mọi trình độ'});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: szInputDecoration(),
      items: [
        DropdownMenuItem(value: null, child: Text(allLabel)),
        for (final (code, label) in levels) DropdownMenuItem(value: code, child: Text(label)),
      ],
      onChanged: onChanged,
    );
  }
}

InputDecoration szInputDecoration({String? hint, String? suffix}) => InputDecoration(
      hintText: hint,
      suffixText: suffix,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFBFDFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
    );

Widget fieldLabel(String text, {String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Row(children: [
        Text(text, style: AppText.labelLg()),
        if (hint != null) ...[const SizedBox(width: 6), Text(hint, style: AppText.bodySm(color: AppColor.textSubtle))],
      ]),
    );

/// Hàng bật/tắt có mô tả.
class ToggleTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;
  const ToggleTile({super.key, required this.value, required this.onChanged, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: value ? AppColor.mint : AppColor.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: value ? const Color(0xFFB9E3C6) : AppColor.border, width: 1.5),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: AppText.labelLg()),
          subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.bodySm()),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
}

void showCommunityError(BuildContext context, Object e) => showSzSnack(context, e is CommunityException ? e.message : 'Có lỗi xảy ra, thử lại nhé', type: SzToast.error);
