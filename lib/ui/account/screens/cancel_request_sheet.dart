import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/ui/chat/friends_view.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Liên hệ chủ sân: tài khoản (nhắn trong app) + số điện thoại cụm sân (Zalo / gọi).
class OwnerContact {
  final String? username;
  final String? phone;
  final String? venueName;

  const OwnerContact({this.username, this.phone, this.venueName});

  factory OwnerContact.fromVenue(CumSanModel? v) => OwnerContact(username: v?.ownerUsername, phone: _clean(v?.sDT), venueName: v?.tenCumSan);

  factory OwnerContact.fromJson(Map<String, dynamic>? j, CumSanModel? v) => OwnerContact(
        username: j?['chuSan'] as String? ?? v?.ownerUsername,
        phone: _clean(j?['soDienThoai'] as String? ?? v?.sDT),
        venueName: j?['tenCumSan'] as String? ?? v?.tenCumSan,
      );

  static String? _clean(String? raw) {
    var p = (raw ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+84')) p = '0${p.substring(3)}';
    return p.isEmpty ? null : p;
  }

  String? get zalo => phone == null ? null : 'https://zalo.me/$phone';
}

const _reasons = ['Thay đổi lịch trình', 'Bận việc đột xuất', 'Không đủ người chơi', 'Thời tiết xấu', 'Lý do sức khoẻ'];

/// Sheet xin huỷ lượt đã xác nhận. Trả về true nếu đã gửi yêu cầu.
Future<bool> showCancelRequestSheet(BuildContext context, {required PhieuDatSanModel phieu, CumSanModel? venue, String? courtName}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CancelRequestSheet(phieu: phieu, venue: venue, courtName: courtName),
  );
  return sent == true;
}

/// Sheet các cách liên hệ chủ sân (khi đang chờ chủ sân xử lý yêu cầu huỷ).
Future<void> showOwnerContactSheet(BuildContext context, OwnerContact contact) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SzSheetHandle(),
          Text('Liên hệ chủ sân', style: AppText.headlineMd()),
          if (contact.venueName != null) Text(contact.venueName!, style: AppText.body(color: AppColor.textMuted)),
          const SizedBox(height: 14),
          OwnerContactButtons(contact: contact),
        ]),
      ),
    ),
  );
}

class OwnerContactButtons extends StatelessWidget {
  final OwnerContact contact;
  const OwnerContactButtons({super.key, required this.contact});

  Future<void> _chat(BuildContext context) => openChatWith(context, username: contact.username!);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (contact.username != null)
        SzButton('Nhắn trong app', icon: Icons.chat_bubble_outline_rounded, expand: true, onPressed: () => _chat(context)),
      if (contact.zalo != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0068FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
            onPressed: () => launchUrl(Uri.parse(contact.zalo!), mode: LaunchMode.externalApplication),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: const Text('Zalo', style: TextStyle(color: Color(0xFF0068FF), fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Text('Nhắn qua Zalo', style: TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ],
      if (contact.phone != null) ...[
        const SizedBox(height: 10),
        SzButton('Gọi ${contact.phone}', icon: Icons.call_outlined, kind: SzButtonKind.soft, expand: true, onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}'))),
      ],
    ]);
  }
}

class _CancelRequestSheet extends StatefulWidget {
  final PhieuDatSanModel phieu;
  final CumSanModel? venue;
  final String? courtName;
  const _CancelRequestSheet({required this.phieu, this.venue, this.courtName});

  @override
  State<_CancelRequestSheet> createState() => _CancelRequestSheetState();
}

class _CancelRequestSheetState extends State<_CancelRequestSheet> {
  final _text = TextEditingController();
  bool _busy = false;
  OwnerContact? _sent;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await PhieuDatSanApi.requestCancel(widget.phieu.maPhieuDat, _text.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      showSzSnack(context, r.message ?? 'Không gửi được yêu cầu', type: SzToast.error);
      return;
    }
    setState(() => _sent = OwnerContact.fromJson(r.lienHe, widget.venue));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.phieu;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SzSheetHandle(),
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: _sent == null ? AppColor.dangerSoft : AppColor.mint, borderRadius: BorderRadius.circular(14)),
              child: Icon(_sent == null ? Icons.event_busy_rounded : Icons.check_circle_rounded, color: _sent == null ? AppColor.danger : AppColor.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_sent == null ? 'Xin huỷ lượt đặt sân' : 'Đã gửi yêu cầu huỷ', style: AppText.headlineMd()),
                Text('${widget.venue?.tenCumSan ?? 'Cụm sân'} · ${widget.courtName ?? ''} · ${Fmt.range(p.batDau, p.ketThuc)}, ${Fmt.dateShort(p.batDau)}',
                    style: AppText.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          if (_sent == null) ..._form() else ..._done(),
        ]),
      ),
    );
  }

  List<Widget> _form() => [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF92400E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Chỉ xin huỷ được trước giờ chơi ít nhất 30 phút. Hoàn tiền theo chính sách của từng sân, chủ sân sẽ trao đổi với bạn.',
                  style: AppText.bodySm(color: const Color(0xFF92400E))),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Lý do huỷ', style: AppText.labelLg()),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _reasons)
            ChoiceChip(
              label: Text(r),
              selected: _text.text == r,
              selectedColor: AppColor.primaryDark,
              labelStyle: TextStyle(color: _text.text == r ? Colors.white : AppColor.text, fontWeight: FontWeight.w600),
              showCheckmark: false,
              onSelected: (_) => setState(() => _text.text = r),
            ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _text,
          maxLength: 300,
          maxLines: 3,
          minLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Hoặc ghi lý do của bạn…'),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: SzButton('Giữ lượt đặt', kind: SzButtonKind.soft, expand: true, onPressed: () => Navigator.pop(context, false))),
          const SizedBox(width: 10),
          Expanded(
            child: SzButton('Gửi yêu cầu', icon: Icons.send_rounded, kind: SzButtonKind.danger, expand: true, loading: _busy, onPressed: _text.text.trim().length < 3 ? null : _submit),
          ),
        ]),
      ];

  List<Widget> _done() => [
        Text('Hệ thống đã nhắn cho chủ sân trong app kèm lý do của bạn. Lượt đặt vẫn được giữ cho đến khi chủ sân xác nhận huỷ; khi đó khung giờ được nhả cho khách khác và bạn sẽ nhận được thông báo.',
            style: AppText.body(color: AppColor.text)),
        const SizedBox(height: 14),
        Text('Muốn xử lý nhanh hơn? Liên hệ trực tiếp chủ sân:', style: AppText.label(color: AppColor.textMuted)),
        const SizedBox(height: 10),
        OwnerContactButtons(contact: _sent!),
        const SizedBox(height: 10),
        SzButton('Xong', kind: SzButtonKind.ghost, expand: true, onPressed: () => Navigator.pop(context, true)),
      ];
}
