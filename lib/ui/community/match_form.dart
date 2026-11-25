import 'package:application/api/community_api.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dữ liệu form mở / sửa trận.
class MatchDraft {
  String kieuChoi = 'DOI';
  int soNguoiToiDa = 4;
  String? trinhDoTu;
  String? trinhDoDen;
  final title = TextEditingController();
  final note = TextEditingController();
  final fee = TextEditingController();
  bool congKhai = true;
  String nganHang = 'MB';
  final account = TextEditingController();
  final owner = TextEditingController();

  MatchDraft();

  factory MatchDraft.fromMatch(MatchInfo m) {
    final d = MatchDraft()
      ..kieuChoi = m.kieuChoi
      ..soNguoiToiDa = m.soNguoiToiDa
      ..trinhDoTu = m.trinhDoTu
      ..trinhDoDen = m.trinhDoDen
      ..congKhai = m.congKhai
      ..nganHang = m.nhanTien?.nganHang ?? 'MB';
    d.title.text = m.tieuDe;
    d.note.text = m.ghiChu ?? '';
    d.fee.text = '${m.chiPhiMoiNguoi}';
    d.account.text = m.nhanTien?.soTaiKhoan ?? '';
    d.owner.text = m.nhanTien?.chuTaiKhoan ?? '';
    return d;
  }

  /// Điền thông tin nhận tiền đã dùng lần trước.
  Future<void> loadSavedBank() async {
    final p = await SharedPreferences.getInstance();
    nganHang = p.getString('match_bank') ?? nganHang;
    account.text = p.getString('match_account') ?? '';
    owner.text = p.getString('match_owner') ?? '';
  }

  Future<void> saveBank() async {
    if (account.text.trim().isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('match_bank', nganHang);
    await p.setString('match_account', account.text.trim());
    await p.setString('match_owner', owner.text.trim());
  }

  int suggestedFee(num courtPrice) => courtPrice <= 0 ? 0 : ((courtPrice / soNguoiToiDa / 1000).ceil() * 1000);

  Map<String, dynamic> toJson() => {
        'kieuChoi': kieuChoi,
        'soNguoiToiDa': soNguoiToiDa,
        'trinhDoTu': trinhDoTu,
        'trinhDoDen': trinhDoDen,
        'tieuDe': title.text.trim().isEmpty ? null : title.text.trim(),
        'ghiChu': note.text.trim().isEmpty ? null : note.text.trim(),
        'chiPhiMoiNguoi': fee.text.trim().isEmpty ? null : int.tryParse(fee.text.trim()),
        'congKhai': congKhai,
        'nganHang': nganHang,
        'soTaiKhoan': account.text.replaceAll(' ', '').isEmpty ? null : account.text.replaceAll(' ', ''),
        'chuTaiKhoan': owner.text.trim().isEmpty ? null : owner.text.trim().toUpperCase(),
      };

  void dispose() {
    for (final c in [title, note, fee, account, owner]) {
      c.dispose();
    }
  }
}

class MatchFields extends StatefulWidget {
  final MatchDraft draft;
  final num courtPrice;
  final bool hasGroup;

  /// Gọi mỗi khi người dùng đổi một giá trị (để màn cha cập nhật phần tóm tắt).
  final VoidCallback? onChanged;
  const MatchFields({super.key, required this.draft, required this.courtPrice, required this.hasGroup, this.onChanged});

  @override
  State<MatchFields> createState() => _MatchFieldsState();
}

class _MatchFieldsState extends State<MatchFields> {
  MatchDraft get d => widget.draft;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final suggested = d.suggestedFee(widget.courtPrice);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      fieldLabel('Kiểu chơi'),
      SzSegmented<String>(
        options: [for (final (code, label, _) in playTypes) (code, label)],
        value: d.kieuChoi,
        onChanged: (v) => setState(() {
          d.kieuChoi = v;
          d.soNguoiToiDa = playTypes.firstWhere((t) => t.$1 == v).$3;
        }),
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            fieldLabel('Số người', hint: 'tính cả bạn'),
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColor.border, width: 1.5), color: const Color(0xFFFBFDFB)),
              child: Row(children: [
                _step(Icons.remove_rounded, () => setState(() => d.soNguoiToiDa = (d.soNguoiToiDa - 1).clamp(2, 24))),
                Expanded(child: Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: Text('${d.soNguoiToiDa}', key: ValueKey(d.soNguoiToiDa), style: AppText.stat(size: 20))))),
                _step(Icons.add_rounded, () => setState(() => d.soNguoiToiDa = (d.soNguoiToiDa + 1).clamp(2, 24))),
              ]),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            fieldLabel('Góp mỗi người'),
            TextField(
              controller: d.fee,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: szInputDecoration(hint: '$suggested', suffix: '₫'),
            ),
          ]),
        ),
      ]),
      if (widget.courtPrice > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColor.primaryDark),
            const SizedBox(width: 4),
            Expanded(child: Text('Tiền sân ${Fmt.money(widget.courtPrice)} ÷ ${d.soNguoiToiDa} người ≈ ${Fmt.money(suggested)}/người', style: AppText.label(color: AppColor.primaryDark))),
          ]),
        ),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Trình độ từ'), LevelDropdown(value: d.trinhDoTu, allLabel: 'Không giới hạn', onChanged: (v) => setState(() => d.trinhDoTu = v))])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Đến'), LevelDropdown(value: d.trinhDoDen, allLabel: 'Không giới hạn', onChanged: (v) => setState(() => d.trinhDoDen = v))])),
      ]),
      fieldLabel('Tiêu đề', hint: 'không bắt buộc'),
      TextField(controller: d.title, maxLength: 80, decoration: szInputDecoration(hint: 'VD: Kèo đôi tối thứ 5, cần 2 bạn TB+').copyWith(counterText: '')),
      fieldLabel('Ghi chú', hint: 'không bắt buộc'),
      TextField(controller: d.note, maxLength: 500, maxLines: 3, decoration: szInputDecoration(hint: 'Ai mang cầu, đánh vui hay tính điểm, gửi xe ở đâu…')),
      if (widget.hasGroup)
        ToggleTile(
          value: d.congKhai,
          onChanged: (v) => setState(() => d.congKhai = v),
          title: 'Mời cả người ngoài nhóm',
          subtitle: d.congKhai ? 'Trận hiện ở mục Tìm trận, người lạ xin vào và bạn duyệt' : 'Chỉ thành viên nhóm thấy và tham gia',
        ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: const Color(0xFFB9E3C6), width: 1.5), color: const Color(0xFFFBFEFC)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          fieldLabel('Nhận tiền góp', hint: 'không bắt buộc'),
          DropdownButtonFormField<String>(
            initialValue: d.nganHang,
            isExpanded: true,
            decoration: szInputDecoration(),
            items: [for (final (code, name, _) in banks) DropdownMenuItem(value: code, child: Text(name))],
            onChanged: (v) => setState(() => d.nganHang = v ?? 'MB'),
          ),
          const SizedBox(height: 10),
          TextField(controller: d.account, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ]'))], decoration: szInputDecoration(hint: 'Số tài khoản (trống nếu thu tiền mặt)')),
          const SizedBox(height: 10),
          TextField(controller: d.owner, textCapitalization: TextCapitalization.characters, decoration: szInputDecoration(hint: 'Tên chủ tài khoản – NGUYEN VAN A')),
          const SizedBox(height: 8),
          Text('Người chơi sẽ thấy mã QR có sẵn số tiền. SmashZone không giữ tiền, chỉ giúp bạn theo dõi ai đã trả.', style: AppText.bodySm()),
        ]),
      ),
    ]);
  }

  Widget _step(IconData icon, VoidCallback onTap) => Material(
        color: AppColor.mint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(borderRadius: BorderRadius.circular(AppRadius.sm), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColor.primaryDark))),
      );
}
