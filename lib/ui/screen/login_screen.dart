import 'package:application/api/account_api.dart';
import 'package:application/ui/screen/register_screen.dart';
import 'package:application/ui/screen/white_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/widget/app_button.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BadmintonLoginScreen();
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class BadmintonLoginScreen extends StatefulWidget {
  const BadmintonLoginScreen({super.key});
  @override
  State<BadmintonLoginScreen> createState() => _BadmintonLoginScreenState();
}

class _BadmintonLoginScreenState extends State<BadmintonLoginScreen>
    with TickerProviderStateMixin {

  final _usernameCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure   = true;
  bool _remember  = false;

  // Shuttlecock arc animation
  late AnimationController _shuttleCtrl;
  late Animation<double>   _shuttleArc;   // 0→1 arc progress
  late Animation<double>   _shuttleAngle; // rotation

  // Fade-in entrance
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Court line pulse
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Shuttlecock arc: loops
    _shuttleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _shuttleArc = CurvedAnimation(
      parent: _shuttleCtrl,
      curve: Curves.easeInOut,
    );
    _shuttleAngle = Tween<double>(begin: -0.8, end: 0.8).animate(
      CurvedAnimation(parent: _shuttleCtrl, curve: Curves.easeInOut),
    );

    // Entrance fade+slide
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();

    // Subtle pulse on court lines
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 0.85).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shuttleCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {

    var result = await AccountApi.login(_usernameCtrl.text, _passwordCtrl.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? '🏸 Smash thành công! Vào sân thôi!' : "Đăng nhập không thành công."
        ),
        backgroundColor: result ? AppColor.kCourtGreen : AppColor.kAccentYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (result) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WhiteScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background court ──────────────────────────────────────
          _CourtBackground(pulseAnim: _pulseAnim, size: size),

          // ── Animated shuttlecock arc ───────────────────────────────
          AnimatedBuilder(
            animation: _shuttleCtrl,
            builder: (context, _) {
              // Parabolic arc across top half
              final t = _shuttleCtrl.value;
              final x = size.width * 0.1 + (size.width * 0.8) * t;
              final y = size.height * 0.05 +
                  (size.height * 0.22) * (4 * t * (1 - t)); // arc peak
              return Positioned(
                left: x - 18,
                top: y - 18,
                child: Transform.rotate(
                  angle: _shuttleAngle.value,
                  child: const _ShuttlecockIcon(size: 36),
                ),
              );
            },
          ),

          // ── Racket decoration top-left ─────────────────────────────
          Positioned(
            top: -10,
            left: -20,
            child: Transform.rotate(
              angle: 0.7,
              child: Opacity(
                opacity: 0.18,
                child: _RacketPainter(width: 90, height: 160),
              ),
            ),
          ),

          // ── Racket decoration bottom-right ─────────────────────────
          Positioned(
            bottom: -20,
            right: -15,
            child: Transform.rotate(
              angle: -0.5,
              child: Opacity(
                opacity: 0.14,
                child: _RacketPainter(width: 80, height: 145),
              ),
            ),
          ),

          // ── Main scrollable content ───────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 36),
                      _buildCard(),
                      const SizedBox(height: 28),
                      _buildSocial(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: logo + title ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo badge
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColor.kAccentYellow,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColor.kAccentYellow.withOpacity(0.55),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColor.kDeepGreen.withOpacity(0.30),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(52, 52),
              painter: _LogoRacketPainter(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'SmashZone',
          style: TextStyle(
            color: AppColor.kLineWhite,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [
              Shadow(color: AppColor.kDeepGreen, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColor.kAccentYellow.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.kAccentYellow.withOpacity(0.5), width: 1),
          ),
          child: const Text(
            '🏸  Ứng dụng cầu lông của bạn',
            style: TextStyle(
              color: AppColor.kLineWhite,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── White card ──────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
      decoration: BoxDecoration(
        color: AppColor.kCardWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColor.kDeepGreen.withOpacity(0.22),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            controller: _usernameCtrl,
            label: 'Email',
            hint: 'vd: player@smash.vn',
            icon: Icons.alternate_email_rounded,
            type: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          _buildField(
            controller: _passwordCtrl,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _CourtCheckbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v),
              ),
              const SizedBox(width: 8),
              Text('Ghi nhớ đăng nhập',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColor.kCourtGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Login button
          AppButton(btnText: "Vào Sân", isLoading: false, onTap: _login),

          const SizedBox(height: 18),

          // Score-style stats bar (decorative)
          _buildScoreBar(),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Chưa có tài khoản? ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13.5)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegisterScreen())
                  );
                },
                child: const Text(
                  'Đăng ký ngay',
                  style: TextStyle(
                    color: AppColor.kCourtGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColor.kTextDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          style: const TextStyle(fontSize: 15, color: AppColor.kTextDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: AppColor.kCourtGreen, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColor.kMintField,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.kCourtGreen, width: 1.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.green[100]!, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  // Decorative scoreboard-style mini widget
  Widget _buildScoreBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.kMintField,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('1,240', 'Thành viên'),
          Container(width: 1, height: 28, color: Colors.green[200]),
          _statItem('86+', 'Sân đấu'),
          Container(width: 1, height: 28, color: Colors.green[200]),
          _statItem('24/7', 'Hỗ trợ'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColor.kCourtGreen,
                fontWeight: FontWeight.w900,
                fontSize: 14)),
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 10.5)),
      ],
    );
  }

  // ── Social login ────────────────────────────────────────────────────────────
  Widget _buildSocial() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Divider(color: AppColor.kLineWhite.withOpacity(0.35))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('hoặc',
                  style: TextStyle(color: AppColor.kLineWhite, fontSize: 13)),
            ),
            Expanded(
                child: Divider(color: AppColor.kLineWhite.withOpacity(0.35))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _socialBtn('Google', Icons.g_mobiledata_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _socialBtn('Facebook', Icons.facebook_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _socialBtn(String label, IconData icon) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColor.kLineWhite.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: AppColor.kLineWhite.withOpacity(0.35), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColor.kLineWhite, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColor.kLineWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

//region design
// ─── Court Background Painter ─────────────────────────────────────────────────
class _CourtBackground extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Size size;
  const _CourtBackground({required this.pulseAnim, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _CourtPainter(lineOpacity: pulseAnim.value),
        );
      },
    );
  }
}

class _CourtPainter extends CustomPainter {
  final double lineOpacity;
  _CourtPainter({required this.lineOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColor.kDeepGreen, AppColor.kCourtGreen, Color(0xFF1F8F42)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = AppColor.kLineWhite.withOpacity(lineOpacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final thinLine = Paint()
      ..color = AppColor.kLineWhite.withOpacity(lineOpacity * 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final double cw = size.width;
    final double ch = size.height;

    // Court boundary (outer)
    final double marginH = cw * 0.06;
    final double marginV = ch * 0.28;
    final Rect court =
    Rect.fromLTRB(marginH, marginV, cw - marginH, ch - 0.04 * ch);
    canvas.drawRect(court, linePaint);

    // Net line (horizontal center)
    final double netY = marginV + (ch - 0.04 * ch - marginV) / 2;
    canvas.drawLine(Offset(marginH, netY), Offset(cw - marginH, netY), linePaint);

    // Short service lines
    final double ssTop = marginV + (netY - marginV) * 0.35;
    final double ssBot = netY + (ch - 0.04 * ch - netY) * 0.35;
    canvas.drawLine(Offset(marginH, ssTop), Offset(cw - marginH, ssTop), thinLine);
    canvas.drawLine(Offset(marginH, ssBot), Offset(cw - marginH, ssBot), thinLine);

    // Center lines (vertical)
    final double cx = cw / 2;
    canvas.drawLine(Offset(cx, marginV), Offset(cx, netY), thinLine);
    canvas.drawLine(Offset(cx, netY), Offset(cx, ch - 0.04 * ch), thinLine);

    // Side tram lines (doubles)
    final double tramLeft  = marginH + cw * 0.08;
    final double tramRight = cw - marginH - cw * 0.08;
    canvas.drawLine(Offset(tramLeft, marginV), Offset(tramLeft, ch - 0.04 * ch), thinLine);
    canvas.drawLine(Offset(tramRight, marginV), Offset(tramRight, ch - 0.04 * ch), thinLine);

    // Net posts circles
    final postPaint = Paint()
      ..color = AppColor.kAccentYellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(marginH, netY), 5, postPaint);
    canvas.drawCircle(Offset(cw - marginH, netY), 5, postPaint);

    // Subtle vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          AppColor.kDeepGreen.withOpacity(0.55),
        ],
      ).createShader(Rect.fromLTWH(0, 0, cw, ch));
    canvas.drawRect(Rect.fromLTWH(0, 0, cw, ch), vignette);
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.lineOpacity != lineOpacity;
}

// ─── Shuttlecock Icon (drawn with CustomPaint) ────────────────────────────────
class _ShuttlecockIcon extends StatelessWidget {
  final double size;
  const _ShuttlecockIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ShuttlePainter(),
    );
  }
}

class _ShuttlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Cork (bottom)
    final corkPaint = Paint()..color = const Color(0xFFEDC97A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w * 0.32, height: h * 0.22),
      corkPaint,
    );

    // Feathers (fan shape from cork top)
    final featherPaint = Paint()
      ..color = AppColor.kShuttleWhite.withOpacity(0.92)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Offset base = Offset(w * 0.5, h * 0.68);
    for (int i = 0; i < 7; i++) {
      final double angle = -math.pi / 2 + (i - 3) * (math.pi / 9);
      final Offset tip = Offset(
        base.dx + math.cos(angle) * h * 0.52,
        base.dy + math.sin(angle) * h * 0.52,
      );
      canvas.drawLine(base, tip, featherPaint);
    }

    // Feather rim arc
    final rimPaint = Paint()
      ..color = AppColor.kShuttleWhite.withOpacity(0.55)
      ..strokeWidth = w * 0.05
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: base, width: h * 1.05, height: h * 1.05),
      -math.pi * 1.05,
      math.pi * 0.1,
      false,
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(_ShuttlePainter _) => false;
}

// ─── Racket Widget (decorative) ───────────────────────────────────────────────
class _RacketPainter extends StatelessWidget {
  final double width;
  final double height;
  const _RacketPainter({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _RacketCustomPainter(),
    );
  }
}

class _RacketCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final framePaint = Paint()
      ..color = AppColor.kLineWhite
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke;

    final stringPaint = Paint()
      ..color = AppColor.kLineWhite.withOpacity(0.6)
      ..strokeWidth = w * 0.025
      ..style = PaintingStyle.stroke;

    // Head oval
    final Rect head = Rect.fromLTRB(w * 0.05, h * 0.02, w * 0.95, h * 0.55);
    canvas.drawOval(head, framePaint);

    // Handle
    canvas.drawLine(
      Offset(w * 0.38, h * 0.52),
      Offset(w * 0.38, h * 0.96),
      framePaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.52),
      Offset(w * 0.62, h * 0.96),
      framePaint,
    );
    canvas.drawLine(
      Offset(w * 0.38, h * 0.96),
      Offset(w * 0.62, h * 0.96),
      framePaint,
    );

    // Strings (vertical)
    for (int i = 1; i <= 5; i++) {
      final double x = head.left + (head.width / 6) * i;
      // Clip to oval roughly
      final double dy = head.height / 2 *
          math.sqrt(
              math.max(0, 1 - math.pow((x - head.center.dx) / (head.width / 2), 2).toDouble()));
      canvas.drawLine(
        Offset(x, head.center.dy - dy + 2),
        Offset(x, head.center.dy + dy - 2),
        stringPaint,
      );
    }

    // Strings (horizontal)
    for (int i = 1; i <= 6; i++) {
      final double y = head.top + (head.height / 7) * i;
      final double dx = head.width / 2 *
          math.sqrt(
              math.max(0, 1 - math.pow((y - head.center.dy) / (head.height / 2), 2).toDouble()));
      canvas.drawLine(
        Offset(head.center.dx - dx + 2, y),
        Offset(head.center.dx + dx - 2, y),
        stringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RacketCustomPainter _) => false;
}

// ─── Logo racket (for the badge) ──────────────────────────────────────────────
class _LogoRacketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = AppColor.kDeepGreen
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Simple racket silhouette
    canvas.drawOval(
      Rect.fromLTRB(w * 0.08, h * 0.04, w * 0.92, h * 0.58),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.56),
      Offset(w * 0.5, h * 0.96),
      paint,
    );

    // Shuttle dot
    final dot = Paint()
      ..color = AppColor.kCourtGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.31), w * 0.12, dot);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Custom checkbox with green court style ───────────────────────────────────
class _CourtCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CourtCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? AppColor.kCourtGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColor.kCourtGreen : Colors.grey[300]!,
            width: 1.6,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: AppColor.kLineWhite, size: 13)
            : null,
      ),
    );
  }
}
//endregion