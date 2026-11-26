import 'dart:async';

import 'package:application/api/ban_be_api.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mở cuộc trò chuyện với một người (dùng chung cho bạn bè, chủ sân, thông báo…).
Future<void> openChatWith(BuildContext context, {required String username, String? fullName, String role = 'ROLE_USER'}) async {
  final prefs = await SharedPreferences.getInstance();
  final me = prefs.getString('username') ?? '';
  if (!context.mounted || me.isEmpty) return;
  var person = Person(username: username, fullName: fullName ?? '', role: role);
  if (fullName == null) person = await BanBeApi.profile(username) ?? person;
  if (!context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(currentUsername: me, peer: person.chatUser)));
}

/// Nút theo quan hệ: Kết bạn / Đã gửi / Đồng ý / Nhắn tin.
class FriendActionButton extends StatefulWidget {
  final Person person;
  final ValueChanged<String>? onChanged;
  final bool compact;
  const FriendActionButton({super.key, required this.person, this.onChanged, this.compact = true});

  @override
  State<FriendActionButton> createState() => _FriendActionButtonState();
}

class _FriendActionButtonState extends State<FriendActionButton> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() fn, String ok) async {
    setState(() => _busy = true);
    try {
      final q = await fn();
      if (!mounted) return;
      showSzSnack(context, ok);
      widget.onChanged?.call(q);
    } catch (e) {
      if (mounted) showSzSnack(context, '$e'.replaceFirst('Exception: ', ''), type: SzToast.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final small = widget.compact;
    Widget button(String label, IconData icon, SzButtonKind kind, VoidCallback? onTap) =>
        small ? SzButton.small(label, icon: icon, kind: kind, loading: _busy, onPressed: onTap) : SzButton(label, icon: icon, kind: kind, loading: _busy, onPressed: onTap);
    return switch (p.quanHe) {
      'BAN_BE' => button('Nhắn tin', Icons.chat_bubble_outline_rounded, SzButtonKind.soft, () => openChatWith(context, username: p.username, fullName: p.fullName, role: p.role)),
      'DA_GUI' => button('Đã gửi', Icons.schedule_rounded, SzButtonKind.ghost, () => _run(() async {
            await BanBeApi.remove(p.username);
            return 'KHONG';
          }, 'Đã huỷ lời mời')),
      'DUOC_MOI' => button('Đồng ý', Icons.how_to_reg_rounded, SzButtonKind.primary, () => _run(() => BanBeApi.accept(p.username), 'Hai bạn đã là bạn bè')),
      _ => button('Kết bạn', Icons.person_add_alt_1_rounded, SzButtonKind.primary, () => _run(() => BanBeApi.invite(p.username), 'Đã gửi lời mời kết bạn')),
    };
  }
}

/// Danh sách bạn bè: tìm người, lời mời đến / đã gửi, bạn bè.
class FriendsView extends StatefulWidget {
  final ValueChanged<int>? onRequestCount;
  const FriendsView({super.key, this.onRequestCount});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  final _search = TextEditingController();
  Timer? _debounce;
  FriendsOverview? _data;
  bool _failed = false;
  List<Person>? _results;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await BanBeApi.overview();
    if (!mounted) return;
    setState(() {
      _data = d ?? _data;
      _failed = d == null && _data == null;
    });
    widget.onRequestCount?.call(d?.incoming.length ?? 0);
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    setState(() => _q = v.trim());
    if (_q.length < 3) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final r = await BanBeApi.search(_q);
      if (mounted && _q.length >= 3) setState(() => _results = r);
    });
  }

  Future<void> _unfriend(Person p) async {
    final ok = await showSzConfirm(context, title: 'Huỷ kết bạn?', message: '${p.displayName} sẽ không còn trong danh sách bạn bè. Tin nhắn cũ vẫn được giữ.', confirmLabel: 'Huỷ kết bạn', icon: Icons.person_remove_alt_1_rounded, destructive: true);
    if (!ok) return;
    await BanBeApi.remove(p.username).catchError((_) {});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SzTextField(controller: _search, hint: 'Tìm bạn: tên đăng nhập, họ tên, số điện thoại', icon: Icons.person_search_rounded, onChanged: _onSearch),
          if (_q.isNotEmpty && _q.length < 3)
            Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text('Nhập ít nhất 3 ký tự, hoặc số điện thoại đầy đủ.', style: AppText.bodySm())),
          if (_results != null) ...[
            _label('Kết quả tìm kiếm'),
            if (_results!.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Không tìm thấy ai. Thử đúng tên đăng nhập hoặc số điện thoại.', style: AppText.body(color: AppColor.textMuted)))
            else
              for (final p in _results!)
                _PersonTile(
                  person: p,
                  trailing: FriendActionButton(
                    person: p,
                    onChanged: (q) {
                      setState(() => _results = [for (final x in _results!) x.username == p.username ? x.withRelation(q) : x]);
                      _load();
                    },
                  ),
                ),
          ],
          if (d == null && !_failed)
            for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(top: 10), child: SzSkeleton(height: 64, radius: AppRadius.lg))
          else if (_failed)
            SzErrorState(message: 'Không tải được danh sách bạn bè.', onRetry: _load)
          else ...[
            if (d!.incoming.isNotEmpty) ...[
              _label('Lời mời kết bạn · ${d.incoming.length}'),
              for (final p in d.incoming)
                _PersonTile(
                  person: p,
                  subtitle: 'muốn kết bạn với bạn',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    FriendActionButton(person: p, onChanged: (_) => _load()),
                    SzIconButton(Icons.close_rounded, size: 36, color: AppColor.textMuted, tooltip: 'Từ chối', onPressed: () async {
                      await BanBeApi.remove(p.username).catchError((_) {});
                      _load();
                    }),
                  ]),
                ),
            ],
            if (d.outgoing.isNotEmpty) ...[
              _label('Đã gửi lời mời'),
              for (final p in d.outgoing) _PersonTile(person: p, subtitle: 'chờ đồng ý', trailing: FriendActionButton(person: p, onChanged: (_) => _load())),
            ],
            _label('Bạn bè · ${d.friends.length}'),
            if (d.friends.isEmpty)
              const SzEmptyState(
                icon: Icons.group_outlined,
                title: 'Chưa có bạn bè',
                message: 'Tìm bạn bằng tên đăng nhập hoặc số điện thoại ở ô phía trên. Chủ sân và người cùng nhóm, cùng trận thì nhắn được ngay, không cần kết bạn.',
              )
            else
              for (final p in d.friends)
                _PersonTile(
                  person: p,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    FriendActionButton(person: p),
                    SzIconButton(Icons.person_remove_outlined, size: 36, color: AppColor.textMuted, tooltip: 'Huỷ kết bạn', onPressed: () => _unfriend(p)),
                  ]),
                ),
          ],
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8), child: Text(t.toUpperCase(), style: AppText.labelSm()));
}

class _PersonTile extends StatelessWidget {
  final Person person;
  final String? subtitle;
  final Widget trailing;
  const _PersonTile({required this.person, this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SzCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          person.role == 'ROLE_OWNER' ? SzAvatar(person.displayName, size: 44) : SzAvatar.soft(person.displayName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(person.displayName, style: AppText.labelLg(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (person.role == 'ROLE_OWNER') const Padding(padding: EdgeInsets.only(left: 6), child: SzPill('Chủ sân', bold: true)),
              ]),
              Text('@${person.username}${subtitle == null ? '' : ' · $subtitle'}', style: AppText.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}

/// Màn Bạn bè đứng riêng (mở từ thông báo lời mời kết bạn).
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SzTopBar(title: 'Bạn bè', subtitle: 'Kết bạn để nhắn tin với người chơi khác'),
      body: FriendsView(),
    );
  }
}
