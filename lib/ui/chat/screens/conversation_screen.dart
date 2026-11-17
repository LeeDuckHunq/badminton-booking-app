// lib/ui/chat/screens/conversation_screen.dart
import 'dart:async';

import 'package:application/api/chat_api.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// M12 – Cuộc trò chuyện 1–1 (làm mới mỗi 3 giây).
class ConversationScreen extends StatefulWidget {
  final String currentUsername;
  final ChatUser peer;

  const ConversationScreen({super.key, required this.currentUsername, required this.peer});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ChatMessage> _messages = [];
  String? _roomId;
  bool _loadingRoom = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initRoom() async {
    setState(() => _loadingRoom = true);
    final roomId = await ChatApi.getOrCreateRoom(username1: widget.currentUsername, username2: widget.peer.username);
    if (!mounted) return;
    setState(() {
      _roomId = roomId;
      _loadingRoom = false;
    });
    if (roomId != null) {
      await _fetch();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch(silent: true));
    }
  }

  Future<void> _fetch({bool silent = false}) async {
    if (_roomId == null || !mounted) return;
    final msgs = await ChatApi.getMessages(_roomId!);
    if (!mounted) return;
    final grew = msgs.length != _messages.where((m) => !m.pending).length;
    setState(() => _messages = msgs);
    if (!silent || grew) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _roomId == null || _sending) return;
    setState(() => _sending = true);
    _inputCtrl.clear();

    final optimistic = ChatMessage(
      maTinNhan: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      maPhongChat: _roomId!,
      usernameNguoiGui: widget.currentUsername,
      noiDung: text,
      thoiGianGui: DateTime.now(),
      pending: true,
    );
    setState(() => _messages = [..._messages, optimistic]);
    _scrollToBottom();

    final ok = await ChatApi.sendMessage(maPhongChat: _roomId!, usernameNguoiGui: widget.currentUsername, noiDung: text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _messages = _messages.where((m) => m.maTinNhan != optimistic.maTinNhan).toList());
      _inputCtrl.text = text;
      showSzSnack(context, 'Gửi tin nhắn thất bại, thử lại nhé', type: SzToast.error);
    }
    await _fetch(silent: true);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: SizedBox(
            height: 72,
            child: Row(children: [
              const SizedBox(width: 4),
              SzIconButton(Icons.arrow_back_rounded, size: 44, onPressed: () => Navigator.pop(context)),
              SzAvatar(peer.displayName, size: 46, online: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(peer.displayName, style: AppText.headlineSm().copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('@${peer.username}${peer.isOwner ? ' · Chủ sân' : ''}', style: AppText.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 12),
            ]),
          ),
        ),
      ),
      body: _loadingRoom
          ? const SzLoading(message: 'Đang mở cuộc trò chuyện…')
          : _roomId == null
              ? SzErrorState(message: 'Không thể tạo phòng chat.', onRetry: _initRoom)
              : Column(children: [
                  Expanded(child: _buildMessages()),
                  _buildInput(),
                ]),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return SzEmptyState(icon: Icons.waving_hand_outlined, title: 'Bắt đầu cuộc trò chuyện nào! 👋', message: 'Gửi lời chào tới ${widget.peer.displayName}.');
    }
    final items = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final day = DateTime(m.thoiGianGui.year, m.thoiGianGui.month, m.thoiGianGui.day);
      if (lastDay == null || day != lastDay) {
        items.add(_DayDivider(day));
        lastDay = day;
      }
      final mine = m.usernameNguoiGui.toLowerCase() == widget.currentUsername.toLowerCase();
      final next = i + 1 < _messages.length ? _messages[i + 1] : null;
      final lastInGroup = next == null || next.usernameNguoiGui != m.usernameNguoiGui || next.thoiGianGui.difference(m.thoiGianGui).inMinutes > 5;
      items.add(_Bubble(message: m, mine: mine, peerName: widget.peer.displayName, showMeta: lastInGroup));
    }
    return ListView(controller: _scrollCtrl, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: items);
  }

  Widget _buildInput() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColor.border)),
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: AppText.bodyLg(),
              cursorColor: AppColor.primary,
              decoration: InputDecoration(border: InputBorder.none, hintText: 'Nhắn tin…', hintStyle: AppText.bodyLg(color: AppColor.textSubtle)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColor.primaryDark,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _sending ? null : _send,
            child: const SizedBox(width: 48, height: 48, child: Icon(Icons.send_rounded, color: Colors.white, size: 22)),
          ),
        ),
      ]),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final DateTime day;
  const _DayDivider(this.day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final label = diff == 0 ? 'Hôm nay, ${Fmt.date(day)}' : (diff == 1 ? 'Hôm qua, ${Fmt.date(day)}' : Fmt.dateLong(day));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFD1F8D5), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColor.primaryDark),
            const SizedBox(width: 6),
            Text(label, style: AppText.label(color: AppColor.primaryDark)),
          ]),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final String peerName;
  final bool showMeta;

  const _Bubble({required this.message, required this.mine, required this.peerName, required this.showMeta});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColor.primaryDark : const Color(0xFFE6F5EC),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : (showMeta ? 4 : 18)),
          bottomRight: Radius.circular(mine ? (showMeta ? 4 : 18) : 18),
        ),
      ),
      child: Text(message.noiDung, style: AppText.bodyLg(color: mine ? Colors.white : AppColor.text)),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: showMeta ? 10 : 3),
      child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (!mine) ...[showMeta ? SzAvatar.soft(peerName, size: 30) : const SizedBox(width: 30), const SizedBox(width: 8)],
          Flexible(child: bubble),
        ]),
        if (showMeta)
          Padding(
            padding: EdgeInsets.only(top: 4, left: mine ? 0 : 38),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(Fmt.hhmm(message.thoiGianGui), style: AppText.labelSm()),
              if (mine) ...[
                const SizedBox(width: 4),
                Icon(message.pending ? Icons.schedule_rounded : Icons.done_all_rounded, size: 14, color: message.pending ? AppColor.textSubtle : AppColor.primary),
              ],
            ]),
          ),
      ]),
    );
  }
}
