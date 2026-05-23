// lib/ui/chat/chat_screen.dart

import 'package:application/api/chat_api.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  List<ChatUser> _users = [];
  List<ChatUser> _filtered = [];
  bool _isLoading = true;
  String? _currentUsername;
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('username') ?? '';
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await ChatApi.getAllUsers();
    if (!mounted) return;
    // Lọc bỏ chính mình
    final filtered =
    users.where((u) => u.username != _currentUsername).toList();
    setState(() {
      _users = filtered;
      _filtered = filtered;
      _isLoading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
          .where((u) =>
      u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q))
          .toList();
    });
  }

  void _openChat(ChatUser peer) {
    if (_currentUsername == null || _currentUsername!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          currentUsername: _currentUsername!,
          peer: peer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: RefreshIndicator(
        color: AppColor.kCourtGreen,
        onRefresh: _loadUsers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColor.kCourtGreen, strokeWidth: 2.5),
                ),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _UserTile(
                    user: _filtered[i],
                    index: i,
                    onTap: () => _openChat(_filtered[i]),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────
  SliverAppBar _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: 165,
      floating: false,
      pinned: true,
      backgroundColor: AppColor.kDeepGreen,
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadUsers,
          icon: _isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColor.kAccentYellow, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'SmashZone',
                      style: TextStyle(
                        color: AppColor.kAccentYellow,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_users.length} người',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Text(
                  'Tin Nhắn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhắn tin với đồng đội của bạn',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: const Text(
        'Tin Nhắn',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm người dùng...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon:
            Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
              icon:
              Icon(Icons.close_rounded, color: Colors.grey[400], size: 18),
              onPressed: () {
                _searchCtrl.clear();
                FocusScope.of(context).unfocus();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.grey[300], size: 52),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy người dùng',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onTap;
  final int index;

  const _UserTile(
      {required this.user, required this.onTap, required this.index});

  Color get _avatarColor {
    final colors = [
      const Color(0xFF1A7A3C),
      const Color(0xFF1565C0),
      const Color(0xFF7B1FA2),
      const Color(0xFFE64A19),
      const Color(0xFF00838F),
      const Color(0xFF558B2F),
      const Color(0xFF4527A0),
    ];
    return colors[user.username.hashCode.abs() % colors.length];
  }

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: AppColor.kTextDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.kMintField,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: AppColor.kCourtGreen, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}