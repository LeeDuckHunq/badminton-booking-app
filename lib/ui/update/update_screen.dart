import 'dart:async';
import 'dart:math' as math;

import 'package:application/services/app_updater.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

bool _prompting = false;

/// Kiểm tra bản mới và mở màn cập nhật nếu cần.
/// [manual] = người dùng tự bấm "Kiểm tra cập nhật" (luôn báo kết quả, bỏ qua "Để sau").
Future<void> checkForUpdate(NavigatorState? navigator, {bool manual = false, BuildContext? messageContext}) async {
  if (navigator == null || _prompting) return;
  final app = await AppUpdater.installed();
  if (app == null) {
    if (manual && messageContext != null && messageContext.mounted) showSzSnack(messageContext, 'Chỉ cập nhật trong app được trên Android', type: SzToast.info);
    return;
  }
  final release = await AppUpdater.fetch(app.build);
  if (release == null || !release.coBanMoi) {
    if (manual && messageContext != null && messageContext.mounted) {
      showSzSnack(messageContext, release == null ? 'Không kiểm tra được, thử lại sau nhé' : 'Bạn đang dùng bản mới nhất (${app.versionName})', type: release == null ? SzToast.warning : SzToast.success);
    }
    return;
  }
  if (!manual && !release.batBuoc && await AppUpdater.isSnoozed(release.soBuild)) return;
  if (!navigator.mounted) return;
  _prompting = true;
  try {
    await navigator.push(PageRouteBuilder(
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => UpdateScreen(release: release, installed: app),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
      ),
    ));
  } finally {
    _prompting = false;
  }
}

/// Tự kiểm tra cập nhật khi mở app và khi quay lại app sau ≥ 3 giờ.
class UpdateWatcher with WidgetsBindingObserver {
  UpdateWatcher._(this._navigatorKey);
  final GlobalKey<NavigatorState> _navigatorKey;
  DateTime? _lastCheck;

  static void start(GlobalKey<NavigatorState> navigatorKey) {
    if (!AppUpdater.supported) return;
    final w = UpdateWatcher._(navigatorKey);
    WidgetsBinding.instance.addObserver(w);
    // Đợi màn đầu tiên vẽ xong rồi mới kiểm tra.
    Future.delayed(const Duration(milliseconds: 1500), w._check);
  }

  void _check() {
    _lastCheck = DateTime.now();
    checkForUpdate(_navigatorKey.currentState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastCheck;
    if (last == null || DateTime.now().difference(last) > const Duration(hours: 3)) _check();
  }
}

enum _Stage { idle, downloading, needPermission, ready, error }

/// Màn "Có bản cập nhật" / "Cần cập nhật để tiếp tục".
class UpdateScreen extends StatefulWidget {
  final AppRelease release;
  final InstalledApp installed;

  /// Chỉ dùng khi xem trước giao diện (không gọi kênh native).
  final bool preview;
  const UpdateScreen({super.key, required this.release, required this.installed, this.preview = false});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  _Stage _stage = _Stage.idle;
  int _received = 0;
  int _total = 0;
  String? _error;
  String? _path;
  UpdateDownload? _download;

  AppRelease get r => widget.release;
  bool get _forced => r.batBuoc;
  (String, String)? get _target => AppUpdater.pickDownload(r, widget.installed.abis);
  int get _size => r.kichThuoc[_target?.$1] ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _download?.cancel();
    _float.dispose();
    _intro.dispose();
    super.dispose();
  }

  /// Quay lại từ màn cài đặt quyền → nếu đã cho phép thì cài luôn.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stage == _Stage.needPermission && _path != null) _install();
  }

  Future<void> _start() async {
    final target = _target;
    if (target == null) {
      setState(() { _stage = _Stage.error; _error = 'Chưa có file cài đặt phù hợp với máy của bạn'; });
      return;
    }
    if (widget.preview) {
      // Xem trước: giả lập tiến độ tải.
      setState(() { _stage = _Stage.downloading; _total = _size; _received = 0; });
      for (var i = 1; i <= 20 && mounted; i++) {
        await Future.delayed(const Duration(milliseconds: 90));
        if (mounted) setState(() => _received = (_total * i / 20).round());
      }
      if (mounted) setState(() => _stage = _Stage.ready);
      return;
    }
    final download = _download = UpdateDownload();
    setState(() { _stage = _Stage.downloading; _received = 0; _total = _size; _error = null; });
    download.progress.listen((p) {
      if (mounted) setState(() { _received = p.$1; _total = p.$2 > 0 ? p.$2 : _size; });
    });
    try {
      final path = await download.run(target.$2, '${widget.installed.updateDir}/smashzone-${r.phienBan}-${target.$1}.apk', expectedSize: _size);
      if (!mounted) return;
      _path = path;
      await _install();
    } on UpdateException catch (e) {
      if (mounted) setState(() { _stage = e.message == 'Đã huỷ tải' ? _Stage.idle : _Stage.error; _error = e.message; });
    }
  }

  Future<void> _install() async {
    if (widget.preview || _path == null) return;
    try {
      if (!await AppUpdater.canInstall()) {
        setState(() => _stage = _Stage.needPermission);
        return;
      }
      setState(() => _stage = _Stage.ready);
      await AppUpdater.install(_path!);
    } catch (e) {
      if (mounted) setState(() { _stage = _Stage.error; _error = 'Không mở được trình cài đặt. Bạn có thể tải bằng trình duyệt'; });
    }
  }

  Future<void> _later() async {
    if (!widget.preview) await AppUpdater.snooze(r.soBuild);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _browser() async {
    final url = _target?.$2;
    if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: !_forced && _stage != _Stage.downloading,
      child: Scaffold(
        backgroundColor: AppColor.forest,
        body: Stack(children: [
          // Nền gradient + các quả cầu bay
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF23955A), AppColor.primaryDark, AppColor.forest]),
              ),
              child: AnimatedBuilder(animation: _float, builder: (_, _) => CustomPaint(painter: _CourtPainter(_float.value))),
            ),
          ),
          Column(children: [
            SizedBox(height: top + 8),
            Row(children: [
              const SizedBox(width: 8),
              if (!_forced && _stage != _Stage.downloading)
                IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), tooltip: 'Để sau', onPressed: _later)
              else
                const SizedBox(height: 48),
            ]),
            Expanded(flex: 5, child: _hero()),
            Expanded(flex: 7, child: _sheet()),
          ]),
        ]),
      ),
    );
  }

  Widget _stagger(double start, Widget child) {
    final anim = CurvedAnimation(parent: _intro, curve: Interval(start, math.min(1, start + 0.45), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(0, 24 * (1 - anim.value)), child: c)),
      child: child,
    );
  }

  Widget _hero() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _stagger(0, AnimatedBuilder(
        animation: _float,
        builder: (_, child) {
          final t = _float.value * 2 * math.pi;
          return Transform.translate(offset: Offset(0, math.sin(t) * 6), child: child);
        },
        child: SizedBox(
          width: 150,
          height: 150,
          child: Stack(alignment: Alignment.center, children: [
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _float,
                builder: (_, _) {
                  final v = (_float.value + i / 3) % 1;
                  return Container(
                    width: 84 + 66 * v,
                    height: 84 + 66 * v,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35 * (1 - v)), width: 2)),
                  );
                },
              ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColor.accent, Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: AppColor.accent.withValues(alpha: 0.45), blurRadius: 30, spreadRadius: 2)],
              ),
              child: Icon(_forced ? Icons.system_security_update_warning_rounded : Icons.rocket_launch_rounded, size: 44, color: AppColor.forest),
            ),
          ]),
        ),
      )),
      const SizedBox(height: 18),
      _stagger(0.12, Text(_forced ? 'Cần cập nhật để tiếp tục' : 'Đã có phiên bản mới!', textAlign: TextAlign.center, style: AppText.display(color: Colors.white).copyWith(fontSize: 26))),
      const SizedBox(height: 8),
      _stagger(0.2, Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          _forced ? 'Phiên bản bạn đang dùng đã cũ và không còn được hỗ trợ. Cập nhật để tiếp tục đặt sân nhé.' : 'SmashZone vừa có bản cập nhật với nhiều tính năng mới. Cập nhật chỉ mất chưa đầy một phút.',
          textAlign: TextAlign.center,
          style: AppText.body(color: Colors.white.withValues(alpha: 0.85)),
        ),
      )),
      const SizedBox(height: 14),
      _stagger(0.28, Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _versionChip(widget.installed.versionName, old: true),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)),
          _versionChip(r.phienBan),
        ]),
      )),
    ]);
  }

  Widget _versionChip(String v, {bool old = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: old ? Colors.white.withValues(alpha: 0.12) : AppColor.accent, borderRadius: BorderRadius.circular(999)),
        child: Text(
          'v$v',
          style: AppText.labelLg(color: old ? Colors.white70 : AppColor.forest).copyWith(fontWeight: FontWeight.w800, decoration: old ? TextDecoration.lineThrough : null, decorationColor: Colors.white70),
        ),
      );

  Widget _sheet() {
    final date = r.ngayPhatHanh;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: AppShadow.sheet),
      child: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 8), children: [
              Row(children: [
                Text('Có gì mới', style: AppText.headlineMd()),
                const Spacer(),
                if (_size > 0) _meta(Icons.download_rounded, formatBytes(_size)),
                if (date != null) ...[const SizedBox(width: 8), _meta(Icons.event_rounded, Fmt.date(date))],
              ]),
              const SizedBox(height: 12),
              if (r.thayDoi.isEmpty) Text('Cải thiện hiệu năng và sửa lỗi.', style: AppText.body(color: AppColor.textMuted)),
              for (final (i, line) in r.thayDoi.indexed)
                _stagger(math.min(0.35 + i * 0.07, 0.55), Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(8)),
                      child: Icon(_iconFor(line), size: 16, color: AppColor.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(line, style: AppText.body()))),
                  ]),
                )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined, color: AppColor.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Tài khoản, lịch đặt và dữ liệu của bạn được giữ nguyên sau khi cập nhật.', style: AppText.bodySm(color: AppColor.text))),
                ]),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 16), child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _actions())),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColor.slot, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: AppColor.textMuted), const SizedBox(width: 4), Text(text, style: AppText.label(color: AppColor.textMuted))]),
      );

  static IconData _iconFor(String line) {
    final s = line.toLowerCase();
    if (s.contains('sửa') || s.contains('lỗi')) return Icons.build_rounded;
    if (s.contains('giá') || s.contains('tiền')) return Icons.payments_outlined;
    if (s.contains('nhóm') || s.contains('trận') || s.contains('cộng đồng')) return Icons.groups_rounded;
    if (s.contains('nhanh') || s.contains('hiệu năng')) return Icons.bolt_rounded;
    if (s.contains('giao diện') || s.contains('đẹp')) return Icons.palette_outlined;
    return Icons.auto_awesome_rounded;
  }

  Widget _actions() {
    switch (_stage) {
      case _Stage.downloading:
        final ratio = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;
        return Column(key: const ValueKey('dl'), mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('Đang tải bản cập nhật…', style: AppText.labelLg()),
            const Spacer(),
            Text(ratio == null ? formatBytes(_received) : '${(ratio * 100).round()}%', style: AppText.headlineSm(color: AppColor.primaryDark)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ratio ?? 0),
              duration: const Duration(milliseconds: 200),
              builder: (_, v, _) => LinearProgressIndicator(value: ratio == null ? null : v, minHeight: 12, backgroundColor: AppColor.mint, color: AppColor.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text(_total > 0 ? '${formatBytes(_received)} / ${formatBytes(_total)}' : 'Đang kết nối…', style: AppText.bodySm()),
            const Spacer(),
            TextButton(onPressed: () => _download?.cancel(), child: Text('Huỷ', style: AppText.labelLg(color: AppColor.textMuted))),
          ]),
        ]);
      case _Stage.needPermission:
        return Column(key: const ValueKey('perm'), mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              Expanded(child: Text('Android cần bạn cho phép SmashZone cài bản cập nhật. Bấm nút bên dưới, bật "Cho phép từ nguồn này" rồi quay lại app.', style: AppText.bodySm(color: const Color(0xFF92400E)))),
            ]),
          ),
          const SizedBox(height: 12),
          SzButton('Mở cài đặt quyền', icon: Icons.settings_rounded, expand: true, onPressed: AppUpdater.openInstallSettings),
        ]);
      case _Stage.ready:
        return Column(key: const ValueKey('ready'), mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColor.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã tải xong. Bấm "Cài đặt" trên màn hình của Android để hoàn tất.', style: AppText.body())),
          ]),
          const SizedBox(height: 12),
          SzButton('Cài đặt ngay', icon: Icons.install_mobile_rounded, expand: true, onPressed: _install),
        ]);
      case _Stage.error:
        return Column(key: const ValueKey('err'), mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColor.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: AppColor.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(_error ?? 'Có lỗi xảy ra', style: AppText.bodySm(color: AppColor.danger))),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SzButton('Tải bằng trình duyệt', kind: SzButtonKind.soft, onPressed: _browser)),
            const SizedBox(width: 10),
            Expanded(child: SzButton('Thử lại', icon: Icons.refresh_rounded, onPressed: _start)),
          ]),
        ]);
      case _Stage.idle:
        return Column(key: const ValueKey('idle'), mainAxisSize: MainAxisSize.min, children: [
          SzButton(_forced ? 'Cập nhật để tiếp tục' : 'Cập nhật ngay', icon: Icons.system_update_rounded, expand: true, onPressed: _start),
          if (!_forced) ...[
            const SizedBox(height: 6),
            SzButton('Để sau', kind: SzButtonKind.ghost, expand: true, onPressed: _later),
          ],
        ]);
    }
  }
}

/// Vạch sân cầu lông mờ + vài quả cầu bay chậm làm nền.
class _CourtPainter extends CustomPainter {
  final double t;
  _CourtPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final w = size.width, h = size.height * 0.45;
    final court = Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.8);
    canvas.drawRect(court, line);
    canvas.drawLine(Offset(court.left, court.center.dy), Offset(court.right, court.center.dy), line);
    canvas.drawLine(Offset(court.center.dx, court.top), Offset(court.center.dx, court.bottom), line);
    canvas.drawLine(Offset(court.left + 22, court.top), Offset(court.left + 22, court.bottom), line);
    canvas.drawLine(Offset(court.right - 22, court.top), Offset(court.right - 22, court.bottom), line);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 7; i++) {
      final phase = (t + i / 7) % 1;
      final x = w * ((i * 0.37 + 0.1) % 1);
      final y = h * (1.05 - phase * 1.1);
      canvas.drawCircle(Offset(x + math.sin((phase + i) * 2 * math.pi) * 12, y), 2.5 + (i % 3), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => old.t != t;
}
