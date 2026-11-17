// lib/ui/screen/chat_screen.dart
import 'package:application/api/chat_api.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Filter { all, owners, chatted }

/// M11 – Tin nhắn (tab).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  List<ChatUser> _users = [];
  List<ChatRoom> _rooms = [];
  bool _loading = true;
  bool _failed = false;
  String _me = '';
  String _query = '';
  _Filter _filter = _Filter.all;
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _me = prefs.getString('username') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final results = await Future.wait([ChatApi.getAllUsers(), ChatApi.getMyRooms()]);
    if (!mounted) return;
    final users = (results[0] as List<ChatUser>).where((u) => u.username.toLowerCase() != _me.toLowerCase()).toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final rooms = results[1] as List<ChatRoom>?;
    setState(() {
      _users = users;
      _rooms = rooms ?? [];
      _failed = rooms == null && users.isEmpty;
      _loading = false;
    });
  }

  bool _matches(ChatUser u) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || u.displayName.toLowerCase().contains(q) || u.username.toLowerCase().contains(q);
  }

  Future<void> _open(ChatUser peer) async {
    if (_me.isEmpty) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(currentUsername: _me, peer: peer)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chattedNames = _rooms.map((r) => r.peer.username.toLowerCase()).toSet();
    final rooms = _rooms.where((r) => _matches(r.peer) && (_filter != _Filter.owners || r.peer.isOwner)).toList();
    final contacts = _filter == _Filter.chatted
        ? <ChatUser>[]
        : _users.where((u) => _matches(u) && !chattedNames.contains(u.username.toLowerCase()) && (_filter != _Filter.owners || u.isOwner)).toList();
    final ownersCount = _users.where((u) => u.isOwner).length;

    return Scaffold(
      body: Column(children: [
        const SzBrandHeader(subtitle: 'Tin nhắn'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(children: [
                  Text('Hộp thư', style: AppText.display(color: AppColor.primaryDark).copyWith(fontSize: 28)),
                  const SizedBox(width: 10),
                  if (!_loading) SzPill('${_rooms.length} hội thoại', bold: false),
                  const Spacer(),
                  SzIconButton(Icons.refresh_rounded, background: Colors.white, color: AppColor.primary, tooltip: 'Làm mới', onPressed: _load),
                ]),
                const SizedBox(height: 14),
                SzTextField(
                  controller: _searchCtrl,
                  hint: 'Tìm người dùng, chủ sân…',
                  icon: Icons.search_rounded,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    SzChip('Tất cả', count: _users.length, selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                    const SizedBox(width: 8),
                    SzChip('Chủ sân', count: ownersCount, selected: _filter == _Filter.owners, onTap: () => setState(() => _filter = _Filter.owners)),
                    const SizedBox(width: 8),
                    SzChip('Đã nhắn', count: _rooms.length, selected: _filter == _Filter.chatted, onTap: () => setState(() => _filter = _Filter.chatted)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SzSkeleton(height: 76, radius: AppRadius.lg))
                else if (_failed)
                  SzErrorState(message: 'Không tải được danh sách tin nhắn.', onRetry: _load)
                else if (rooms.isEmpty && contacts.isEmpty)
                  const SzEmptyState(icon: Icons.forum_outlined, title: 'Không có ai phù hợp', message: 'Thử tìm bằng tên hoặc tên đăng nhập khác.')
                else ...[
                  if (rooms.isNotEmpty) ...[
                    _sectionLabel('Cuộc trò chuyện'),
                    for (final r in rooms) _RoomTile(room: r, onTap: () => _open(r.peer)),
                  ],
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _sectionLabel(rooms.isEmpty ? 'Danh bạ' : 'Bắt đầu trò chuyện mới'),
                    for (final u in contacts) _ContactTile(user: u, onTap: () => _open(u)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text.toUpperCase(), style: AppText.labelSm()));
}

String _relativeTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return Fmt.hhmm(t);
  if (diff == 1) return 'Hôm qua';
  if (diff < 7) return Fmt.weekdayShort(t) == 'CN' ? 'Chủ nhật' : 'Thứ ${Fmt.weekdayShort(t).substring(1)}';
  return '${Fmt.two(t.day)}/${Fmt.two(t.month)}';
}

class _RoleTag extends StatelessWidget {
  final ChatUser user;
  const _RoleTag(this.user);

  @override
  Widget build(BuildContext context) {
    if (user.isOwner) return const Padding(padding: EdgeInsets.only(left: 6), child: SzPill('Chủ sân', bold: true));
    if (user.isAdmin) return const Padding(padding: EdgeInsets.only(left: 6), child: SzPill('Quản trị', bg: Color(0xFFDBEAFE), fg: Color(0xFF1D4ED8)));
    return const SizedBox.shrink();
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  const _RoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SzCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(children: [
          room.peer.isOwner ? SzAvatar(room.peer.displayName, size: 52) : SzAvatar.soft(room.peer.displayName, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(room.peer.displayName, style: AppText.headlineSm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                _RoleTag(room.peer),
                const Spacer(),
                Text(_relativeTime(room.lastTime), style: AppText.label(color: AppColor.primary)),
              ]),
              Text('@${room.peer.username}', style: AppText.bodySm()),
              const SizedBox(height: 4),
              Text(
                room.lastMessage?.isNotEmpty == true ? room.lastMessage! : 'Chưa có tin nhắn',
                style: AppText.body(color: room.lastMessage?.isNotEmpty == true ? AppColor.text : AppColor.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onTap;
  const _ContactTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SzCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(children: [
          SzAvatar.soft(user.displayName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(user.displayName, style: AppText.labelLg(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                _RoleTag(user),
              ]),
              Text('@${user.username}', style: AppText.bodySm()),
            ]),
          ),
          const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColor.primary),
        ]),
      ),
    );
  }
}
