import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class CourtBackground extends StatefulWidget {
  final Widget child;

  final Duration animationDuration;

  final double pulseOpacityMin;

  final double pulseOpacityMax;

  const CourtBackground({
    super.key,
    required this.child,
    this.animationDuration = const Duration(seconds: 2),
    this.pulseOpacityMin = 0.5,
    this.pulseOpacityMax = 0.85,
  });

  @override
  State<CourtBackground> createState() => _CourtBackgroundState();
}

class _CourtBackgroundState extends State<CourtBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: widget.pulseOpacityMin,
      end: widget.pulseOpacityMax,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Nền sân
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _CourtPainter(lineOpacity: _pulseAnim.value),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

// ─── Painter nội bộ ────────────────────────────────────────────────────────────

class _CourtPainter extends CustomPainter {
  final double lineOpacity;
  const _CourtPainter({required this.lineOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final double cw = size.width;
    final double ch = size.height;

    // Nền gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColor.kDeepGreen, AppColor.kCourtGreen, Color(0xFF1F8F42)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, cw, ch));
    canvas.drawRect(Rect.fromLTWH(0, 0, cw, ch), bgPaint);

    final linePaint = Paint()
      ..color = AppColor.kLineWhite.withOpacity(lineOpacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final thinLine = Paint()
      ..color = AppColor.kLineWhite.withOpacity(lineOpacity * 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Biên ngoài sân
    final double marginH = cw * 0.06;
    final double marginV = ch * 0.28;
    final Rect court =
    Rect.fromLTRB(marginH, marginV, cw - marginH, ch - 0.04 * ch);
    canvas.drawRect(court, linePaint);

    // Đường lưới (giữa dọc)
    final double netY = marginV + (ch - 0.04 * ch - marginV) / 2;
    canvas.drawLine(Offset(marginH, netY), Offset(cw - marginH, netY), linePaint);

    // Đường phát cầu ngắn
    final double ssTop = marginV + (netY - marginV) * 0.35;
    final double ssBot = netY + (ch - 0.04 * ch - netY) * 0.35;
    canvas.drawLine(Offset(marginH, ssTop), Offset(cw - marginH, ssTop), thinLine);
    canvas.drawLine(Offset(marginH, ssBot), Offset(cw - marginH, ssBot), thinLine);

    // Đường trung tâm (dọc)
    final double cx = cw / 2;
    canvas.drawLine(Offset(cx, marginV), Offset(cx, netY), thinLine);
    canvas.drawLine(Offset(cx, netY), Offset(cx, ch - 0.04 * ch), thinLine);

    // Đường biên đôi (tram lines)
    final double tramLeft = marginH + cw * 0.08;
    final double tramRight = cw - marginH - cw * 0.08;
    canvas.drawLine(Offset(tramLeft, marginV), Offset(tramLeft, ch - 0.04 * ch), thinLine);
    canvas.drawLine(Offset(tramRight, marginV), Offset(tramRight, ch - 0.04 * ch), thinLine);

    // Cột lưới
    final postPaint = Paint()
      ..color = AppColor.kAccentYellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(marginH, netY), 5, postPaint);
    canvas.drawCircle(Offset(cw - marginH, netY), 5, postPaint);

    // Vignette
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