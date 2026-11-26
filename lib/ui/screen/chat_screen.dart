// lib/ui/screen/chat_screen.dart
import 'package:application/api/ban_be_api.dart';
import 'package:application/api/chat_api.dart';
import 'package:application/ui/chat/friends_view.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Filter { all, owners, people }

/// M11 – Tin nhắn (tab): Trò chuyện | Bạn bè. Không còn danh bạ toàn bộ người dùng.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  List<ChatRoom> _rooms = [];
  bool _loading = true;
  bool _failed = false;
  String _me = '';
  String _query = '';
  _Filter _filter = _Filter.all;
  int _view = 0;
  int _requests = 0;
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
    final friends = await BanBeApi.overview();
    if (mounted && friends != null) setState(() => _requests = friends.incoming.length);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final rooms = await ChatApi.getMyRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms ?? [];
      _failed = rooms == null;
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
    return Scaffold(
      body: Column(children: [
        const SzBrandHeader(subtitle: 'Tin nhắn'),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _Tabs(
            index: _view,
            requests: _requests,
            onChanged: (i) => setState(() => _view = i),
          ),
        ),
        Expanded(
          child: IndexedStack(index: _view, children: [
            _conversations(),
            FriendsView(onRequestCount: (n) => setState(() => _requests = n)),
          ]),
        ),
      ]),
    );
  }

  Widget _conversations() {
    final rooms = _rooms.where((r) => _matches(r.peer) && switch (_filter) {
          _Filter.owners => r.peer.isOwner,
          _Filter.people => !r.peer.isOwner && !r.peer.isAdmin,
          _ => true,
        }).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            Text('Hộp thư', style: AppText.display(color: AppColor.primaryDark).copyWith(fontSize: 26)),
            const SizedBox(width: 10),
            if (!_loading) SzPill('${_rooms.length} hội thoại', bold: false),
            const Spacer(),
            SzIconButton(Icons.refresh_rounded, background: Colors.white, color: AppColor.primary, tooltip: 'Làm mới', onPressed: _load),
          ]),
          const SizedBox(height: 12),
          SzTextField(controller: _searchCtrl, hint: 'Tìm trong cuộc trò chuyện…', icon: Icons.search_rounded, onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              SzChip('Tất cả', count: _rooms.length, selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
              const SizedBox(width: 8),
              SzChip('Chủ sân', count: _rooms.where((r) => r.peer.isOwner).length, selected: _filter == _Filter.owners, onTap: () => setState(() => _filter = _Filter.owners)),
              const SizedBox(width: 8),
              SzChip('Bạn bè & cộng đồng', selected: _filter == _Filter.people, onTap: () => setState(() => _filter = _Filter.people)),
            ]),
          ),
          const SizedBox(height: 16),
          if (_loading)
            for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SzSkeleton(height: 76, radius: AppRadius.lg))
          else if (_failed)
            SzErrorState(message: 'Không tải được danh sách tin nhắn.', onRetry: _load)
          else if (rooms.isEmpty)
            Column(children: [
              SzEmptyState(
                icon: Icons.forum_outlined,
                title: _query.isEmpty ? 'Chưa có tin nhắn' : 'Không tìm thấy cuộc trò chuyện',
                message: 'Nhắn chủ sân bằng nút "Nhắn chủ sân" ở trang đặt sân, hoặc kết bạn để nhắn với người chơi khác.',
              ),
              SzButton.small('Tìm bạn bè', icon: Icons.person_search_rounded, kind: SzButtonKind.soft, onPressed: () => setState(() => _view = 1)),
            ])
          else
            for (final r in rooms) _RoomTile(room: r, onTap: () => _open(r.peer)),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final int requests;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.index, required this.requests, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(int i, String label, {int badge = 0}) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 40,
              decoration: BoxDecoration(
                color: index == i ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: index == i ? AppShadow.card : null,
              ),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: AppText.labelLg(color: index == i ? AppColor.primaryDark : AppColor.textMuted)),
                if (badge > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColor.danger, borderRadius: BorderRadius.circular(9)),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(13)),
      child: Row(children: [tab(0, 'Trò chuyện'), tab(1, 'Bạn bè', badge: requests)]),
    );
  }
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
