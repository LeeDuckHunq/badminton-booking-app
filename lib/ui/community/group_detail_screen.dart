import 'dart:async';

import 'package:application/api/community_api.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/community/create_match_screen.dart';
import 'package:application/ui/community/group_sheets.dart';
import 'package:application/ui/community/match_detail_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _GTab { matches, chat, members }

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupInfo? _g;
  Object? _error;
  bool _private = false;
  String _me = '';
  _GTab _tab = _GTab.matches;
  List<MatchInfo>? _matches;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final prefs = await SharedPreferences.getInstance();
    _me = prefs.getString('username') ?? '';
    try {
      final g = await CommunityApi.group(widget.groupId);
      if (!mounted) return;
      setState(() { _g = g; _private = false; });
      if (g.isMember) _loadMatches();
    } on CommunityException catch (e) {
      if (!mounted) return;
      setState(() { if (e.status == 403) { _private = true; } else { _error = e; } });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMatches() async {
    try {
      final list = await CommunityApi.groupMatches(widget.groupId);
      if (mounted) setState(() => _matches = list);
    } catch (_) {
      if (mounted) setState(() => _matches = []);
    }
  }

  Future<void> _act(Future<GroupInfo> Function() fn, [String? message]) async {
    try {
      final g = await fn();
      if (!mounted) return;
      setState(() { _g = g; _private = false; });
      if (g.isMember && _matches == null) _loadMatches();
      if (message != null) showSzSnack(context, message);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    }
  }

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    showSzSnack(context, message, type: SzToast.info);
  }

  Future<void> _menu(String v) async {
    final g = _g!;
    switch (v) {
      case 'edit':
        final updated = await showGroupFormSheet(context, group: g);
        if (updated != null && mounted) setState(() => _g = updated);
      case 'code':
        await _act(() => CommunityApi.newCode(g.maNhom), 'Đã đổi mã mời mới, mã cũ hết hiệu lực');
      case 'leave':
        final ok = await showSzConfirm(context, title: 'Rời nhóm?', message: g.isOwner ? (g.soThanhVien > 1 ? 'Bạn là trưởng nhóm, hãy chuyển quyền cho người khác trước khi rời.' : 'Bạn là thành viên cuối cùng, rời nhóm sẽ giải tán nhóm.') : 'Bạn có thể vào lại bằng mã mời.', confirmLabel: 'Rời nhóm', icon: Icons.logout_rounded, destructive: true);
        if (!ok) return;
        try {
          await CommunityApi.leaveGroup(g.maNhom);
          if (!mounted) return;
          showSzSnack(context, 'Bạn đã rời nhóm');
          Navigator.pop(context);
        } catch (e) {
          if (mounted) showCommunityError(context, e);
        }
      case 'disband':
        final ok = await showSzConfirm(context, title: 'Giải tán nhóm?', message: 'Thành viên, tin nhắn nhóm sẽ bị xoá và các trận sắp tới của nhóm bị huỷ. Không thể hoàn tác.', confirmLabel: 'Giải tán', icon: Icons.delete_forever_rounded, destructive: true);
        if (!ok) return;
        try {
          await CommunityApi.disband(g.maNhom);
          if (!mounted) return;
          showSzSnack(context, 'Đã giải tán nhóm');
          Navigator.pop(context);
        } catch (e) {
          if (mounted) showCommunityError(context, e);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: const SzTopBar(title: 'Nhóm'), body: SzErrorState(message: '$_error', onRetry: _load));
    if (_private) {
      return Scaffold(
        appBar: const SzTopBar(title: 'Nhóm riêng tư'),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const SzEmptyState(icon: Icons.lock_outline_rounded, title: 'Nhóm riêng tư', message: 'Bạn cần mã mời từ trưởng nhóm để tham gia.'),
          _JoinBox(group: null, onJoin: (code, msg) => _act(() => CommunityApi.joinGroup(widget.groupId, maMoi: code), 'Chào mừng bạn vào nhóm!')),
        ]),
      );
    }
    final g = _g;
    if (g == null) return const Scaffold(appBar: SzTopBar(title: 'Nhóm'), body: SzLoading());

    final header = _header(g);
    if (!g.isMember) {
      return Scaffold(
        backgroundColor: AppColor.canvas,
        body: ListView(padding: EdgeInsets.zero, children: [
          header,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _JoinBox(
                group: g,
                onJoin: (code, msg) => _act(() => CommunityApi.joinGroup(g.maNhom, maMoi: code, loiNhan: msg), code == null ? 'Đã gửi yêu cầu tham gia' : 'Chào mừng bạn vào nhóm!'),
                onCancel: () async {
                  try {
                    await CommunityApi.cancelRequest(g.maNhom);
                    _load();
                  } catch (e) {
                    if (context.mounted) showCommunityError(context, e);
                  }
                },
              ),
              const SizedBox(height: 12),
              SzCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SzSectionTitle(Icons.groups_rounded, 'Thành viên tiêu biểu'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final n in g.thanhVienTieuBieu) Chip(avatar: SzAvatar.soft(n, size: 24), label: Text(n), backgroundColor: AppColor.canvas, side: BorderSide.none)]),
                  if (g.truongNhom != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Trưởng nhóm: ${g.truongNhom!.ten}', style: AppText.bodySm())),
                ]),
              ),
            ]),
          ),
        ]),
      );
    }

    final upcoming = (_matches ?? []).where((m) => !m.finished).toList();
    final tabs = [
      (_GTab.matches, upcoming.isEmpty ? 'Trận' : 'Trận (${upcoming.length})'),
      (_GTab.chat, 'Trò chuyện'),
      (_GTab.members, g.isLeader && g.yeuCau.isNotEmpty ? 'Thành viên · ${g.yeuCau.length}' : 'Thành viên'),
    ];
    return Scaffold(
      backgroundColor: AppColor.canvas,
      floatingActionButton: _tab == _GTab.matches && !g.khoa
          ? FloatingActionButton.extended(
              heroTag: 'group-fab',
              backgroundColor: AppColor.primaryDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Mở trận cho nhóm'),
              onPressed: () async {
                final created = await Navigator.push<MatchInfo>(context, MaterialPageRoute(builder: (_) => CreateMatchScreen(groupId: g.maNhom)));
                if (created != null && context.mounted) {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: created.maTran)));
                }
                _loadMatches();
              },
            )
          : null,
      body: Column(children: [
        header,
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: SzSegmented<_GTab>(options: tabs, value: _tab, onChanged: (t) => setState(() => _tab = t))),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_tab) {
              _GTab.matches => _matchesView(key: const ValueKey('m')),
              _GTab.chat => _GroupChat(key: const ValueKey('c'), group: g, me: _me),
              _GTab.members => _membersView(g, key: const ValueKey('t')),
            },
          ),
        ),
      ]),
    );
  }

  Widget _header(GroupInfo g) {
    return Container(
      decoration: BoxDecoration(gradient: groupGradient(g.mau)),
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.maybePop(context)),
          const Spacer(),
          if (g.isMember)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: _menu,
              itemBuilder: (_) => [
                if (g.isLeader && !g.khoa) const PopupMenuItem(value: 'edit', child: Text('Sửa thông tin nhóm')),
                if (g.isLeader && !g.khoa) const PopupMenuItem(value: 'code', child: Text('Đổi mã mời')),
                const PopupMenuItem(value: 'leave', child: Text('Rời nhóm')),
                if (g.isOwner) const PopupMenuItem(value: 'disband', child: Text('Giải tán nhóm', style: TextStyle(color: AppColor.danger))),
              ],
            ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white70, width: 2.5)),
                child: GroupAvatar(name: g.tenNhom, mau: g.mau, size: 62),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.tenNhom, style: AppText.headlineLg(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${g.khuVuc ?? 'Chưa đặt khu vực'} · ${g.soThanhVien} thành viên', style: AppText.body(color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _glass(g.congKhai ? 'Công khai' : 'Riêng tư', g.congKhai ? Icons.public_rounded : Icons.lock_outline_rounded),
                    _glass(g.trinhDo == null ? 'Mọi trình độ' : 'Trình ${levelLabel(g.trinhDo)}', null),
                    if (g.isMember) _glass(roleLabel(g.vaiTro ?? ''), g.isOwner ? Icons.workspace_premium_rounded : null),
                  ]),
                ]),
              ),
            ]),
            if (g.moTa != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(g.moTa!, style: AppText.body(color: Colors.white.withValues(alpha: 0.92)))),
            if (g.khoa)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColor.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(children: [const Icon(Icons.shield_outlined, color: AppColor.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text('Nhóm đã bị quản trị viên khoá. Không thể nhắn tin hay mở trận mới.', style: AppText.label(color: AppColor.danger)))]),
              ),
            if (g.isMember && g.maMoi != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                child: Row(children: [
                  Text('Mã mời', style: AppText.bodySm(color: Colors.white70)),
                  const SizedBox(width: 8),
                  Text(g.maMoi!, style: AppText.headlineSm(color: AppColor.accent).copyWith(letterSpacing: 3, fontSize: 18)),
                  const Spacer(),
                  _inviteBtn('Mã', Icons.copy_rounded, () => _copy(g.maMoi!, 'Đã sao chép mã mời')),
                  const SizedBox(width: 6),
                  _inviteBtn('Link', Icons.link_rounded, () => _copy('$kWebBase/nhom/${g.maNhom}?ma=${g.maMoi}', 'Đã sao chép link mời')),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _glass(String text, IconData? icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(text, style: AppText.label(color: Colors.white).copyWith(fontSize: 11.5)),
        ]),
      );

  Widget _inviteBtn(String label, IconData icon, VoidCallback onTap) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Row(children: [Icon(icon, size: 15, color: AppColor.forest), const SizedBox(width: 4), Text(label, style: AppText.label(color: AppColor.forest))])),
        ),
      );

  Widget _matchesView({Key? key}) {
    final list = _matches;
    if (list == null) return const SzLoading(key: ValueKey('ml'));
    final upcoming = list.where((m) => !m.finished).toList();
    final past = list.where((m) => m.finished).take(6).toList();
    Future<void> open(MatchInfo m) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.maTran)));
      _loadMatches();
    }

    return RefreshIndicator(
      key: key,
      onRefresh: _loadMatches,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
        if (upcoming.isEmpty)
          const SzEmptyState(icon: Icons.sports_tennis_rounded, title: 'Chưa có trận nào sắp tới', message: 'Ai đã đặt sân thì mở trận cho nhóm, mọi người vào điểm danh và góp tiền.')
        else
          for (final m in upcoming) Padding(padding: const EdgeInsets.only(bottom: 12), child: MatchCard(m: m, onTap: () => open(m))),
        if (past.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: 8, bottom: 10), child: Text('Đã qua', style: AppText.headlineSm(color: AppColor.textMuted))),
          for (final m in past) Padding(padding: const EdgeInsets.only(bottom: 12), child: MatchCard(m: m, onTap: () => open(m))),
        ],
      ]),
    );
  }

  Widget _membersView(GroupInfo g, {Key? key}) {
    return RefreshIndicator(
      key: key,
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        if (g.isLeader && g.yeuCau.isNotEmpty) ...[
          SzCard(
            border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SzSectionTitle(Icons.person_add_alt_1_rounded, 'Yêu cầu tham gia', trailing: SzPill('${g.yeuCau.length}', bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309))),
              const SizedBox(height: 8),
              for (final p in g.yeuCau)
                _memberRow(p, trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  SzIconButton(Icons.close_rounded, size: 36, background: AppColor.slot, color: AppColor.textMuted, tooltip: 'Từ chối', onPressed: () => _act(() => CommunityApi.reviewMember(g.maNhom, p.username, false), 'Đã từ chối yêu cầu')),
                  const SizedBox(width: 6),
                  SzButton.small('Duyệt', icon: Icons.check_rounded, onPressed: () => _act(() => CommunityApi.reviewMember(g.maNhom, p.username, true), 'Đã nhận ${p.ten} vào nhóm')),
                ])),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        SzCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SzSectionTitle(Icons.groups_rounded, 'Thành viên', trailing: SzPill('${g.soThanhVien}')),
            const SizedBox(height: 8),
            for (final p in g.thanhVien)
              _memberRow(p, trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (p.username != _me)
                  SzIconButton(Icons.chat_bubble_outline_rounded, size: 36, background: AppColor.mint, color: AppColor.primaryDark, tooltip: 'Nhắn riêng',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(currentUsername: _me, peer: ChatUser(username: p.username, fullName: p.ten))))),
                if (g.isLeader && p.username != _me && _canManage(g, p))
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColor.textMuted),
                    onSelected: (v) => _memberAction(g, p, v),
                    itemBuilder: (_) => [
                      if (g.isOwner && p.vaiTro == 'THANH_VIEN') const PopupMenuItem(value: 'PHO_NHOM', child: Text('Đặt làm phó nhóm')),
                      if (g.isOwner && p.vaiTro == 'PHO_NHOM') const PopupMenuItem(value: 'THANH_VIEN', child: Text('Bỏ quyền phó nhóm')),
                      if (g.isOwner) const PopupMenuItem(value: 'TRUONG_NHOM', child: Text('Chuyển quyền trưởng nhóm')),
                      if (p.vaiTro != 'TRUONG_NHOM') const PopupMenuItem(value: 'kick', child: Text('Mời ra khỏi nhóm', style: TextStyle(color: AppColor.danger))),
                    ],
                  ),
              ])),
          ]),
        ),
      ]),
    );
  }

  bool _canManage(GroupInfo g, GroupMember p) => g.isOwner || p.vaiTro == 'THANH_VIEN';

  Future<void> _memberAction(GroupInfo g, GroupMember p, String v) async {
    if (v == 'kick') {
      final ok = await showSzConfirm(context, title: 'Mời ${p.ten} ra khỏi nhóm?', message: 'Họ có thể vào lại bằng mã mời mới.', confirmLabel: 'Mời ra', icon: Icons.person_remove_outlined, destructive: true);
      if (ok) await _act(() => CommunityApi.kickMember(g.maNhom, p.username), 'Đã mời ra khỏi nhóm');
      return;
    }
    if (v == 'TRUONG_NHOM') {
      final ok = await showSzConfirm(context, title: 'Chuyển quyền trưởng nhóm?', message: '${p.ten} sẽ là trưởng nhóm, bạn trở thành phó nhóm.', confirmLabel: 'Chuyển quyền', icon: Icons.workspace_premium_rounded);
      if (!ok) return;
    }
    await _act(() => CommunityApi.setRole(g.maNhom, p.username, v), 'Đã cập nhật vai trò');
  }

  Widget _memberRow(GroupMember p, {Widget? trailing}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(children: [
          p.vaiTro == 'TRUONG_NHOM' ? SzAvatar(p.ten, size: 40) : SzAvatar.soft(p.ten, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.username == _me ? '${p.ten} (bạn)' : p.ten, style: AppText.labelLg()),
              const SizedBox(height: 2),
              Row(children: [
                if (p.vaiTro != 'THANH_VIEN') ...[
                  SzPill(roleLabel(p.vaiTro), bg: p.vaiTro == 'TRUONG_NHOM' ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE), fg: p.vaiTro == 'TRUONG_NHOM' ? const Color(0xFFB45309) : const Color(0xFF1D4ED8)),
                  const SizedBox(width: 6),
                ],
                Flexible(child: Text('@${p.username}', overflow: TextOverflow.ellipsis, style: AppText.bodySm())),
              ]),
              if (p.loiNhan != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('“${p.loiNhan}”', style: AppText.bodySm(color: const Color(0xFF4B5563)).copyWith(fontStyle: FontStyle.italic))),
            ]),
          ),
          ?trailing,
        ]),
      );
}

class _JoinBox extends StatefulWidget {
  final GroupInfo? group;
  final Future<void> Function(String? code, String? message) onJoin;
  final Future<void> Function()? onCancel;
  const _JoinBox({required this.group, required this.onJoin, this.onCancel});

  @override
  State<_JoinBox> createState() => _JoinBoxState();
}

class _JoinBoxState extends State<_JoinBox> {
  final _msg = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _msg.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(String? code) async {
    setState(() => _busy = true);
    await widget.onJoin(code, code == null ? _msg.text.trim() : null);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final pending = g?.isPending == true;
    final canRequest = g != null && g.congKhai && !pending && !g.khoa;
    return SzCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SzSectionTitle(Icons.meeting_room_outlined, pending ? 'Đã gửi yêu cầu tham gia' : 'Tham gia nhóm'),
        const SizedBox(height: 8),
        if (pending) ...[
          Text('Trưởng nhóm hoặc phó nhóm sẽ duyệt sớm. Có mã mời thì nhập để vào ngay.', style: AppText.body(color: AppColor.textMuted)),
          const SizedBox(height: 10),
          SzButton('Huỷ yêu cầu', kind: SzButtonKind.outline, onPressed: widget.onCancel),
        ],
        if (canRequest) ...[
          TextField(controller: _msg, maxLength: 300, maxLines: 2, decoration: szInputDecoration(hint: 'Giới thiệu ngắn: trình độ, giờ hay chơi…')),
          const SizedBox(height: 6),
          SzButton('Xin vào nhóm', icon: Icons.person_add_alt_1_rounded, loading: _busy, onPressed: () => _run(null)),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('hoặc', style: AppText.bodySm())), const Expanded(child: Divider())])),
        ],
        if (pending) const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _code,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: szInputDecoration(hint: 'Mã mời').copyWith(counterText: '', prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColor.primary)),
            ),
          ),
          const SizedBox(width: 8),
          SzButton.small('Vào bằng mã', onPressed: _code.text.trim().length == 6 && !_busy ? () => _run(_code.text.trim().toUpperCase()) : null),
        ]),
      ]),
    );
  }
}

class _GroupChat extends StatefulWidget {
  final GroupInfo group;
  final String me;
  const _GroupChat({super.key, required this.group, required this.me});

  @override
  State<_GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<_GroupChat> {
  List<GroupMessage>? _messages;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final list = await CommunityApi.messages(widget.group.maNhom);
      if (!mounted) return;
      final grew = (_messages?.length ?? -1) != list.length;
      setState(() => _messages = list);
      if (grew) _toBottom();
    } catch (_) {
      if (mounted && _messages == null) setState(() => _messages = []);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final msg = await CommunityApi.send(widget.group.maNhom, text);
      if (!mounted) return;
      setState(() => _messages = [...?_messages, msg]);
      _toBottom();
    } catch (e) {
      _input.text = text;
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _messages;
    return Column(children: [
      Expanded(
        child: list == null
            ? const SzLoading()
            : list.isEmpty
                ? Center(child: Text('👋 Chào cả nhóm một câu nào!', style: AppText.body(color: AppColor.textMuted)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final msg = list[i];
                      final prev = i > 0 ? list[i - 1] : null;
                      final newDay = prev == null || prev.thoiGian.day != msg.thoiGian.day || prev.thoiGian.month != msg.thoiGian.month;
                      final sep = newDay
                          ? Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(999)), child: Text(Fmt.dateLong(msg.thoiGian), style: AppText.label(color: AppColor.primaryDark))))
                          : const SizedBox.shrink();
                      if (msg.heThong) {
                        return Column(children: [
                          sep,
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFFFFF8D1), borderRadius: BorderRadius.circular(12)),
                              child: Text(msg.noiDung, textAlign: TextAlign.center, style: AppText.label(color: const Color(0xFF78350F))),
                            ),
                          ),
                        ]);
                      }
                      final mine = msg.username == widget.me;
                      final grouped = !newDay && !prev.heThong && prev.username == msg.username;
                      return Column(children: [
                        sep,
                        Padding(
                          padding: EdgeInsets.only(top: grouped ? 2 : 8),
                          child: Row(mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            if (!mine) grouped ? const SizedBox(width: 34) : Padding(padding: const EdgeInsets.only(right: 6), child: SzAvatar.soft(msg.ten ?? '', size: 28)),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                decoration: BoxDecoration(
                                  color: mine ? AppColor.primary : Colors.white,
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(mine ? 16 : 4), bottomRight: Radius.circular(mine ? 4 : 16)),
                                  border: mine ? null : Border.all(color: const Color(0xFFE6EFE9)),
                                  boxShadow: AppShadow.card,
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (!mine && !grouped) Text(msg.ten ?? '', style: AppText.label(color: AppColor.primaryDark)),
                                  Text(msg.noiDung, style: AppText.body(color: mine ? Colors.white : AppColor.text)),
                                  Align(alignment: Alignment.centerRight, child: Text(Fmt.hhmm(msg.thoiGian), style: AppText.bodySm(color: mine ? Colors.white70 : AppColor.textSubtle).copyWith(fontSize: 10.5))),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ]);
                    },
                  ),
      ),
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: !widget.group.khoa,
                maxLength: 2000,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: szInputDecoration(hint: widget.group.khoa ? 'Nhóm đã bị khoá' : 'Nhắn cho cả nhóm…').copyWith(counterText: '', fillColor: AppColor.canvas),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColor.primaryDark,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.group.khoa ? null : _send,
                child: SizedBox(width: 46, height: 46, child: _sending ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
