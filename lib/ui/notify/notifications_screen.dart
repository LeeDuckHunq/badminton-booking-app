import 'package:application/api/thong_bao_api.dart';
import 'package:application/services/notification_center.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// Chuông thông báo (có số chưa đọc) — đặt trên header các tab.
class NotificationBell extends StatelessWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final center = NotificationCenter.instance;
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        final n = center.unread;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Material(
            color: n > 0 ? AppColor.mint : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: color ?? AppColor.primaryDark, size: 24),
                  if (n > 0)
                    Positioned(
                      top: 3,
                      right: 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(color: AppColor.danger, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
                        alignment: Alignment.center,
                        child: Text(n > 99 ? '99+' : '$n', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Danh sách thông báo: nhóm theo ngày, lọc chưa đọc / đặt sân / tin nhắn / cộng đồng.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['Tất cả', 'Chưa đọc', 'Đặt sân', 'Tin nhắn', 'Cộng đồng'];
  String _filter = 'Tất cả';
  final _center = NotificationCenter.instance;

  @override
  void initState() {
    super.initState();
    _center.refresh();
    _center.refreshPermission();
  }

  String _groupOf(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Hôm nay';
    if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return 'Trước đó';
  }

  String _time(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${Fmt.hhmm(d)} · ${Fmt.dateShort(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SzTopBar(
        title: 'Thông báo',
        subtitle: 'Đặt sân, tin nhắn và ghép trận',
        actions: [
          ListenableBuilder(
            listenable: _center,
            builder: (_, _) => _center.unread == 0
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: _center.markAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Đọc hết'),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _center,
        builder: (context, _) {
          final list = _center.items.where((n) => switch (_filter) {
                'Chưa đọc' => !n.daDoc,
                'Tất cả' => true,
                _ => n.style.$4 == _filter,
              }).toList();
          final rows = <Widget>[];
          String? group;
          for (final n in list) {
            final g = _groupOf(n.thoiGian);
            if (g != group) {
              group = g;
              rows.add(Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 6), child: Text(g.toUpperCase(), style: AppText.labelSm())));
            }
            rows.add(_tile(n));
          }
          return RefreshIndicator(
            onRefresh: _center.refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (NotificationCenter.nativeSupported && _center.systemPermitted == false) _permissionCard(),
                Container(
                  color: Colors.white,
                  height: 58,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    children: [
                      for (final f in _filters) ...[
                        SzChip(f, count: f == 'Chưa đọc' ? _center.unread : null, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                if (!_center.loaded)
                  const Padding(padding: EdgeInsets.only(top: 80), child: SzLoading(message: 'Đang tải thông báo…'))
                else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: SzEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: _filter == 'Tất cả' ? 'Chưa có thông báo' : 'Không có thông báo phù hợp',
                      message: 'Xác nhận đặt sân, đổi sân, tin nhắn và hoạt động ghép trận sẽ hiện ở đây.',
                    ),
                  )
                else
                  ...rows,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _permissionCard() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColor.forest, AppColor.primary]),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(children: [
          const Icon(Icons.notifications_off_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Thông báo đang tắt', style: AppText.labelLg(color: Colors.white)),
              Text('Bật để biết ngay khi sân được xác nhận, bị đổi hoặc có tin nhắn.', style: AppText.bodySm(color: Colors.white70)),
            ]),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColor.accent, foregroundColor: AppColor.forest),
            onPressed: () => _center.requestPermission(openSettingsIfDenied: true),
            child: const Text('Bật'),
          ),
        ]),
      );

  Widget _tile(ThongBao n) {
    final (icon, fg, bg, _) = n.style;
    return Material(
      color: n.daDoc ? Colors.white : const Color(0xFFF1FAF4),
      child: InkWell(
        onTap: () => _center.open(n),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFF3F0)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: fg, size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.tieuDe, style: (n.daDoc ? AppText.label(color: AppColor.text) : AppText.labelLg(color: AppColor.text))),
                const SizedBox(height: 3),
                Text(n.noiDung, style: AppText.bodySm(color: const Color(0xFF4B5563)), maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_time(n.thoiGian), style: AppText.labelSm()),
              ]),
            ),
            if (!n.daDoc) Container(margin: const EdgeInsets.only(left: 8, top: 6), width: 9, height: 9, decoration: const BoxDecoration(color: AppColor.primary, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }
}
