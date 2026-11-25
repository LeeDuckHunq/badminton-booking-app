import 'package:application/api/community_api.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: child),
    );

/// Tạo nhóm mới, hoặc sửa nhóm khi truyền [group].
Future<GroupInfo?> showGroupFormSheet(BuildContext context, {GroupInfo? group}) => _sheet(context, _GroupForm(group: group));

Future<GroupInfo?> showJoinCodeSheet(BuildContext context) => _sheet(context, const _JoinCode());

class _GroupForm extends StatefulWidget {
  final GroupInfo? group;
  const _GroupForm({this.group});

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  late final _name = TextEditingController(text: widget.group?.tenNhom ?? '');
  late final _area = TextEditingController(text: widget.group?.khuVuc ?? '');
  late final _desc = TextEditingController(text: widget.group?.moTa ?? '');
  late String? _level = widget.group?.trinhDo;
  late bool _public = widget.group?.congKhai ?? true;
  late int _color = widget.group?.mau ?? DateTime.now().millisecond % 6;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) {
      showSzSnack(context, 'Tên nhóm cần ít nhất 3 ký tự', type: SzToast.warning);
      return;
    }
    setState(() => _busy = true);
    final body = {'tenNhom': _name.text.trim(), 'khuVuc': _area.text.trim(), 'moTa': _desc.text.trim(), 'trinhDo': _level, 'congKhai': _public, 'mau': _color};
    try {
      final g = widget.group == null ? await CommunityApi.createGroup(body) : await CommunityApi.updateGroup(widget.group!.maNhom, body);
      if (!mounted) return;
      showSzSnack(context, widget.group == null ? 'Đã tạo nhóm! Gửi mã mời cho bạn bè nhé' : 'Đã lưu thông tin nhóm');
      Navigator.pop(context, g);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const SzSheetHandle(),
          SzSheetHeader(title: widget.group == null ? 'Tạo nhóm mới' : 'Sửa thông tin nhóm', subtitle: widget.group == null ? 'Lập hội chơi cố định, điểm danh và chia tiền dễ dàng' : null, icon: Icons.groups_rounded),
          const SizedBox(height: 14),
          Row(children: [
            AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: GroupAvatar(key: ValueKey(_color), name: _name.text.isEmpty ? 'Nhóm' : _name.text, mau: _color, size: 60)),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (var c = 0; c < 6; c++)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(gradient: groupGradient(c), shape: BoxShape.circle, border: Border.all(color: c == _color ? AppColor.text : Colors.white, width: c == _color ? 2.5 : 3)),
                    ),
                  ),
              ]),
            ),
          ]),
          fieldLabel('Tên nhóm'),
          TextField(controller: _name, maxLength: 60, onChanged: (_) => setState(() {}), decoration: szInputDecoration(hint: 'VD: CLB Cầu Lông Quận 7').copyWith(counterText: '')),
          fieldLabel('Khu vực'),
          TextField(controller: _area, maxLength: 80, decoration: szInputDecoration(hint: 'VD: Quận 7, TP.HCM').copyWith(counterText: '')),
          fieldLabel('Trình độ chính'),
          LevelDropdown(value: _level, onChanged: (v) => setState(() => _level = v)),
          fieldLabel('Giới thiệu', hint: 'không bắt buộc'),
          TextField(controller: _desc, maxLength: 500, maxLines: 3, decoration: szInputDecoration(hint: 'Lịch chơi, phong cách, quy định của nhóm…')),
          ToggleTile(
            value: _public,
            onChanged: (v) => setState(() => _public = v),
            title: _public ? 'Nhóm công khai' : 'Nhóm riêng tư',
            subtitle: _public ? 'Hiện ở Khám phá, người lạ gửi yêu cầu để bạn duyệt' : 'Chỉ vào được bằng mã mời',
          ),
          const SizedBox(height: 18),
          SzButton(widget.group == null ? 'Tạo nhóm' : 'Lưu thay đổi', icon: Icons.auto_awesome_rounded, expand: true, loading: _busy, onPressed: _submit),
        ]),
      ),
    );
  }
}

class _JoinCode extends StatefulWidget {
  const _JoinCode();

  @override
  State<_JoinCode> createState() => _JoinCodeState();
}

class _JoinCodeState extends State<_JoinCode> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().length < 6) return;
    setState(() => _busy = true);
    try {
      final g = await CommunityApi.joinByCode(_code.text.trim().toUpperCase());
      if (!mounted) return;
      showSzSnack(context, 'Chào mừng bạn đến với ${g.tenNhom}!');
      Navigator.pop(context, g);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SzSheetHandle(),
          const SzSheetHeader(title: 'Nhập mã mời', subtitle: 'Mã gồm 6 ký tự, trưởng nhóm gửi cho bạn', icon: Icons.vpn_key_rounded),
          const SizedBox(height: 18),
          TextField(
            controller: _code,
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')), _UpperCase()],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            style: AppText.display(color: AppColor.forest).copyWith(letterSpacing: 10),
            decoration: szInputDecoration(hint: 'ABC123').copyWith(counterText: '', fillColor: AppColor.mint),
          ),
          const SizedBox(height: 14),
          SzButton('Vào nhóm', icon: Icons.groups_rounded, expand: true, loading: _busy, onPressed: _code.text.length == 6 ? _submit : null),
        ]),
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) => newValue.copyWith(text: newValue.text.toUpperCase());
}
