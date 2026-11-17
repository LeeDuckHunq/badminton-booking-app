import 'package:application/api/account_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/ui/screen/home_screen.dart';
import 'package:application/ui/screen/register_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M1 – Đăng nhập.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _remember = true;
  bool _loading = false;
  String? _error;

  int? _userCount;
  int? _courtCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final results = await Future.wait([AccountApi.amountOfAccount(), SanApi.amountOfCourt()]);
    if (!mounted) return;
    setState(() {
      _userCount = results[0];
      _courtCount = results[1];
    });
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên đăng nhập và mật khẩu');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    bool ok = false;
    try {
      ok = await AccountApi.login(username, password);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Sai tên đăng nhập hoặc mật khẩu';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_login', _remember);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (!mounted) return;
    if (registered == true) {
      showSzSnack(context, 'Đăng ký thành công! Hãy đăng nhập để vào sân.');
    }
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFFEA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const AuthHero(title: 'Sẵn sàng ra sân?'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _StatCard(label: 'Cộng đồng', value: _userCount, unit: 'vợt thủ', icon: Icons.groups_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Sân trên hệ thống', value: _courtCount, unit: 'sân', icon: Icons.stadium_rounded, highlight: true)),
            ]),
            const SizedBox(height: 16),
            SzCard(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              radius: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Đăng nhập tài khoản', style: AppText.headlineMd()),
                      const SizedBox(height: 4),
                      Text('Vào sân và theo dõi lịch đặt của bạn', style: AppText.body(color: AppColor.textMuted)),
                    ]),
                  ),
                  Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColor.mint, shape: BoxShape.circle), child: const Icon(Icons.verified_user_outlined, color: AppColor.primary, size: 22)),
                ]),
                const SizedBox(height: 24),
                SzTextField(
                  controller: _usernameCtrl,
                  label: 'Tên đăng nhập',
                  labelHint: 'Bắt buộc',
                  hint: 'Nhập tên đăng nhập',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _error == null ? null : setState(() => _error = null),
                ),
                const SizedBox(height: 18),
                SzTextField(
                  controller: _passwordCtrl,
                  label: 'Mật khẩu',
                  labelHint: 'Tối thiểu 6 ký tự',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  onChanged: (_) => _error == null ? null : setState(() => _error = null),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _remember = !_remember),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(children: [
                    Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                    Text('Ghi nhớ đăng nhập', style: AppText.body()),
                  ]),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(_error!),
                ],
                const SizedBox(height: 18),
                SzButton('Vào Sân', expand: true, height: 56, loading: _loading, trailingIcon: Icons.sports_score_rounded, kind: SzButtonKind.dark, onPressed: _login),
              ]),
            ),
            const SizedBox(height: 24),
            AuthFooterLink(text: 'Chưa có tài khoản?', action: 'Đăng ký', onTap: _openRegister),
          ],
        ),
      ),
    );
  }
}

/// Khối thương hiệu ở đầu màn Đăng nhập / Đăng ký.
class AuthHero extends StatelessWidget {
  final String title;
  const AuthHero({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(color: const Color(0xFFD1F8D5), borderRadius: BorderRadius.circular(24), boxShadow: AppShadow.card),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(right: -24, top: 18, bottom: -30, width: 180, child: CustomPaint(painter: _CourtLinesPainter())),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColor.primaryDark, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('ĐẶT SÂN CẦU LÔNG', style: AppText.labelSm(color: AppColor.primaryDark)),
              ]),
            ),
            const Spacer(),
            Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                const SzLogo(size: 64),
                Positioned(top: -4, right: -4, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColor.accent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD1F8D5), width: 3)))),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SmashZone', style: AppText.display(color: AppColor.primary).copyWith(fontSize: 28, height: 1.1)),
                  Text(title, style: AppText.headlineLg(color: AppColor.text)),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _CourtLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFB4E8BC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(10));
    canvas.drawRRect(r, p);
    canvas.drawLine(Offset(0, size.height * 0.42), Offset(size.width, size.height * 0.42), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.42), Offset(size.width * 0.5, size.height), p);
    canvas.drawLine(Offset(size.width * 0.15, 0), Offset(size.width * 0.15, size.height), p);
    canvas.drawLine(Offset(size.width * 0.85, 0), Offset(size.width * 0.85, size.height), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatCard extends StatelessWidget {
  final String label;
  final int? value;
  final String unit;
  final IconData icon;
  final bool highlight;

  const _StatCard({required this.label, required this.value, required this.unit, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SzCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: AppText.body(color: AppColor.textMuted))),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: highlight ? const Color(0xFFB2F2BA) : AppColor.mint, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppColor.primaryDark),
          ),
        ]),
        const SizedBox(height: 10),
        value == null
            ? const SzSkeleton(width: 80, height: 28)
            : Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(Fmt.number(value!), style: AppText.stat(size: 30, color: highlight ? AppColor.primary : AppColor.forest)),
                const SizedBox(width: 6),
                Text(unit, style: AppText.label(color: AppColor.textMuted)),
              ]),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColor.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFCA5A5))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColor.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: AppText.label(color: const Color(0xFFB91C1C)))),
      ]),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({super.key, required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(text, style: AppText.bodyLg(color: AppColor.textMuted)),
      TextButton(onPressed: onTap, child: Text(action, style: AppText.bodyLg(color: AppColor.primaryDark).copyWith(fontWeight: FontWeight.w700))),
    ]);
  }
}
