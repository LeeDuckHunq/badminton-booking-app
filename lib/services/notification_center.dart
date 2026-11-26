import 'dart:async';

import 'package:application/api/api_client.dart';
import 'package:application/api/ban_be_api.dart';
import 'package:application/ui/chat/friends_view.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/server_address.dart';
import 'package:application/api/thong_bao_api.dart';
import 'package:application/ui/account/screens/booking_history_screen.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/community/match_detail_screen.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trung tâm thông báo trong app.
/// <ul>
///   <li>Khi app đang mở: hỏi máy chủ mỗi 20 giây, hiện băng thông báo trên đầu màn hình và số trên chuông.</li>
///   <li>Khi app ở nền / đã tắt (Android): phần native (WorkManager) hỏi máy chủ và hiện thông báo hệ thống.</li>
///   <li>Bấm thông báo (trong app hoặc trên thanh trạng thái) → mở đúng màn hình.</li>
/// </ul>
class NotificationCenter extends ChangeNotifier with WidgetsBindingObserver {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  static const _channel = MethodChannel('vn.smashzone.app/notify');
  static const _pollEvery = Duration(seconds: 20);

  GlobalKey<NavigatorState>? _navigator;
  Timer? _timer;
  bool _running = false;
  bool _busy = false;
  OverlayEntry? _banner;
  Timer? _bannerTimer;

  List<ThongBao> items = [];
  int unread = 0;
  bool loaded = false;
  bool? systemPermitted;

  static bool get nativeSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void attach(GlobalKey<NavigatorState> navigator) => _navigator = navigator;

  /// Gọi sau khi đăng nhập / khi vào trang chủ. Gọi nhiều lần không sao.
  Future<void> start() async {
    if (_running) {
      unawaited(_tick());
      return;
    }
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    if (nativeSupported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'open' && call.arguments is Map) _openTarget(Map<String, dynamic>.from(call.arguments as Map));
        return null;
      });
      await _configureNative();
      try {
        await _channel.invokeMethod('foreground');
        final initial = await _channel.invokeMethod<Map>('initialTarget');
        if (initial != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _openTarget(Map<String, dynamic>.from(initial)));
        }
      } catch (_) {}
      unawaited(_askPermissionOnce());
    }
    await _tick(first: true);
    _schedule();
  }

  /// Đăng xuất: ngừng hỏi, xoá thông báo trên máy.
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _hideBanner();
    items = [];
    unread = 0;
    loaded = false;
    notifyListeners();
    if (nativeSupported) {
      try {
        await _channel.invokeMethod('clear');
      } catch (_) {}
    }
  }

  Future<void> _configureNative() async {
    final token = await ApiClient.token();
    if (token == null) return;
    try {
      await _channel.invokeMethod('configure', {'baseUrl': ServerAddress().address, 'token': token});
      systemPermitted = await _channel.invokeMethod<bool>('permitted');
    } catch (_) {}
  }

  Future<void> _askPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notify_permission_asked') == true) return;
    await prefs.setBool('notify_permission_asked', true);
    await requestPermission();
  }

  /// Xin quyền hiện thông báo (Android 13+). Nếu đã bị từ chối hẳn thì mở cài đặt.
  Future<void> requestPermission({bool openSettingsIfDenied = false}) async {
    if (!nativeSupported) return;
    try {
      final ok = await _channel.invokeMethod<bool>('requestPermission');
      if (ok != true && openSettingsIfDenied) await _channel.invokeMethod('openSettings');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      systemPermitted = await _channel.invokeMethod<bool>('permitted');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshPermission() async {
    if (!nativeSupported) return;
    try {
      systemPermitted = await _channel.invokeMethod<bool>('permitted');
      notifyListeners();
    } catch (_) {}
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollEvery, (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _hideBanner();
      if (nativeSupported) _channel.invokeMethod('background').catchError((_) => null);
    } else if (state == AppLifecycleState.resumed) {
      if (nativeSupported) {
        _channel.invokeMethod('foreground').catchError((_) => null);
        unawaited(refreshPermission());
      }
      unawaited(_tick());
      _schedule();
    }
  }

  /// Lấy thông báo mới (đánh dấu đã gửi để điện thoại không báo lại) + danh sách cho chuông.
  Future<void> _tick({bool first = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final fresh = await ThongBaoApi.takePending();
      final data = await ThongBaoApi.list();
      if (data != null) {
        items = data.items;
        unread = data.unread;
        loaded = true;
        notifyListeners();
      }
      if (fresh.isNotEmpty) _showBanner(fresh.last, more: fresh.length - 1);
    } finally {
      _busy = false;
    }
  }

  Future<void> refresh() => _tick();

  Future<void> markRead(ThongBao n) async {
    if (n.daDoc) return;
    items = [for (final x in items) x.maThongBao == n.maThongBao ? x.read() : x];
    unread = (unread - 1).clamp(0, 1 << 20);
    notifyListeners();
    await ThongBaoApi.markRead(n.maThongBao);
  }

  Future<void> markAllRead() async {
    items = [for (final x in items) x.read()];
    unread = 0;
    notifyListeners();
    await ThongBaoApi.markAllRead();
  }

  Future<void> open(ThongBao n) async {
    unawaited(markRead(n));
    await _openTarget({'doiTuong': n.doiTuong, 'maDoiTuong': n.maDoiTuong, 'maThongBao': n.maThongBao});
  }

  Future<void> _openTarget(Map<String, dynamic> t) async {
    final nav = _navigator?.currentState;
    if (nav == null) return;
    final id = '${t['maDoiTuong'] ?? ''}';
    final notificationId = t['maThongBao'] as String?;
    if (notificationId != null) {
      final match = items.where((x) => x.maThongBao == notificationId);
      if (match.isNotEmpty) unawaited(markRead(match.first));
    }
    switch (t['doiTuong']) {
      case 'BOOKING':
        nav.push(MaterialPageRoute(builder: (_) => BookingHistoryScreen.loader(focusId: id)));
      case 'MATCH':
        nav.push(MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: id)));
      case 'CHAT':
        final prefs = await SharedPreferences.getInstance();
        final me = prefs.getString('username') ?? '';
        final peer = await BanBeApi.profile(id);
        if (me.isNotEmpty) {
          nav.push(MaterialPageRoute(builder: (_) => ConversationScreen(currentUsername: me, peer: (peer ?? Person(username: id, fullName: '')).chatUser)));
        }
      case 'FRIEND':
        nav.push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
      case 'REVIEW':
        final venue = await CumSanApi.getCumSanInfo(id);
        if (venue != null) nav.push(MaterialPageRoute(builder: (_) => BookingScheduleScreen(cumSan: venue)));
    }
  }

  // ── Băng thông báo trong app ─────────────────────────────────────────────

  void _showBanner(ThongBao n, {int more = 0}) {
    final overlay = _navigator?.currentState?.overlay;
    if (overlay == null) return;
    _hideBanner();
    _banner = OverlayEntry(
      builder: (_) => _InAppBanner(
        n: n,
        more: more,
        onTap: () {
          _hideBanner();
          open(n);
        },
        onDismiss: _hideBanner,
      ),
    );
    overlay.insert(_banner!);
    HapticFeedback.lightImpact();
    _bannerTimer = Timer(const Duration(seconds: 5), _hideBanner);
  }

  void _hideBanner() {
    _bannerTimer?.cancel();
    _banner?.remove();
    _banner = null;
  }
}

class _InAppBanner extends StatefulWidget {
  final ThongBao n;
  final int more;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppBanner({required this.n, required this.more, required this.onTap, required this.onDismiss});

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg, _) = widget.n.style;
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.of(context).padding.top + 8,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
        child: Dismissible(
          key: ValueKey(widget.n.maThongBao),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.white,
            elevation: 10,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border(left: BorderSide(color: fg, width: 4))),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: fg, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(child: Text(widget.n.tieuDe, style: AppText.labelLg(color: AppColor.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (widget.more > 0) Text('+${widget.more}', style: AppText.label(color: AppColor.primary)),
                      ]),
                      const SizedBox(height: 2),
                      Text(widget.n.noiDung, style: AppText.bodySm(color: AppColor.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
