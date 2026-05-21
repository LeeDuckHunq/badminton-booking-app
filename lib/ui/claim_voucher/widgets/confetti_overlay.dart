import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatelessWidget {
  final double progress;
  const ConfettiOverlay({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  static final _rng = Random(42);
  static final _particles = List.generate(60, (_) => _Particle(_rng));

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final opacity = progress < 0.7 ? 1.0 : (1.0 - progress) / 0.3;

    for (final p in _particles) {
      final x = p.x * size.width;
      final y = p.startY * size.height + progress * p.speed * size.height;
      final paint = Paint()
        ..color = p.color.withOpacity((opacity * p.opacity).clamp(0, 1));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotation * pi * 2);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size * 2, height: p.size),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double rotation;
  final double opacity;
  final bool isCircle;
  final Color color;

  static const _colors = [
    Color(0xFFFFD600),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  _Particle(Random rng)
      : x = rng.nextDouble(),
        startY = -rng.nextDouble() * 0.4,
        speed = 0.6 + rng.nextDouble() * 0.8,
        size = 4 + rng.nextDouble() * 6,
        rotation = rng.nextDouble() * 4 - 2,
        opacity = 0.6 + rng.nextDouble() * 0.4,
        isCircle = rng.nextBool(),
        color = _colors[rng.nextInt(_colors.length)];
}