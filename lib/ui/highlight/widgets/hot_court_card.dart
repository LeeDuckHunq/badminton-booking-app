// lib/ui/highlight/widgets/hot_court_card.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import '../models/hot_court_model.dart';

// Màu gradient cho từng rank (thay cho ảnh nếu không có)
const _rankGradients = [
  [Color(0xFF0D3B20), Color(0xFF1A7A3C), Color(0xFF4CAF72)], // #1 deep emerald
  [Color(0xFF1A237E), Color(0xFF1565C0), Color(0xFF42A5F5)], // #2 cobalt
  [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFBA68C8)], // #3 purple
  [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784)], // #4
  [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF90A4AE)], // #5+
];

class HotCourtCard extends StatelessWidget {
  final HotCourtItem item;
  final VoidCallback onTap;

  const HotCourtCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _gradientStart.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ── Background gradient ──────────────────────────────────
              _buildBackground(),

              // ── Court pattern overlay ────────────────────────────────
              Positioned.fill(child: _CourtPatternOverlay()),

              // ── Noise texture feel ───────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Top-left: Rank badge ─────────────────────────────────
              Positioned(
                top: 16,
                left: 16,
                child: _RankBadge(rank: item.rank),
              ),

              // ── Top-right: Booking count ─────────────────────────────
              Positioned(
                top: 16,
                right: 16,
                child: _BookingCountBadge(count: item.rankData.soLuongDat),
              ),

              // ── Bottom: Court info ───────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CourtInfoPanel(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final idx = (item.rank - 1).clamp(0, _rankGradients.length - 1);
    final colors = _rankGradients[idx];

    if (item.imageUrl != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBg(colors),
            ),
          ),
          // Tint overlay để text luôn đọc được
          Positioned.fill(
            child: Container(
              color: colors[0].withOpacity(0.4),
            ),
          ),
        ],
      );
    }
    return _gradientBg(colors);
  }

  Widget _gradientBg(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Color get _gradientStart {
    final idx = (item.rank - 1).clamp(0, _rankGradients.length - 1);
    return _rankGradients[idx][0];
  }
}

// ── Rank badge (top-left) ─────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _rankStyle(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_rankIcon(rank), color: fg, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _rankStyle(int rank) {
    switch (rank) {
      case 1:
        return ('#1 HOT', const Color(0xFFFFD600), const Color(0xFF1A1A00));
      case 2:
        return ('#2', const Color(0xFFE8E8E8), const Color(0xFF333333));
      case 3:
        return ('#3', const Color(0xFFCD7F32), Colors.white);
      default:
        return ('#$rank', Colors.white.withOpacity(0.2), Colors.white);
    }
  }

  IconData _rankIcon(int rank) {
    switch (rank) {
      case 1: return Icons.local_fire_department_rounded;
      case 2: return Icons.star_rounded;
      case 3: return Icons.workspace_premium_rounded;
      default: return Icons.sports_tennis_rounded;
    }
  }
}

// ── Booking count badge (top-right) ──────────────────────────────────────────
class _BookingCountBadge extends StatelessWidget {
  final int count;
  const _BookingCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        backgroundBlendMode: BlendMode.multiply,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: AppColor.kAccentYellow, size: 12),
          const SizedBox(width: 5),
          Text(
            '$count lượt đặt',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Court info panel (bottom) ─────────────────────────────────────────────────
class _CourtInfoPanel extends StatelessWidget {
  final HotCourtItem item;
  const _CourtInfoPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    final court = item.cumSan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên sân
                Text(
                  court.tenCumSan,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.15,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Địa chỉ
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: Colors.white.withOpacity(0.8), size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        court.diaChi,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Giờ mở cửa
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: AppColor.kAccentYellow.withOpacity(0.9),
                        size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_trimTime(court.gioMoCua)} – ${_trimTime(court.gioDongCua)}',
                      style: TextStyle(
                        color: AppColor.kAccentYellow.withOpacity(0.9),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Nút đặt sân
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.kAccentYellow,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kAccentYellow.withOpacity(0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'ĐẶT\nSÂN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.kDeepGreen,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1.3,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cắt "05:00:00" → "05:00"
  String _trimTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }
}

// ── Court pattern background overlay ─────────────────────────────────────────
class _CourtPatternOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CourtLinePainter(),
    );
  }
}

class _CourtLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Court boundary
    canvas.drawRect(
      Rect.fromLTRB(w * 0.08, h * 0.12, w * 0.92, h * 0.88),
      p,
    );
    // Net line
    canvas.drawLine(
      Offset(w * 0.08, h * 0.5),
      Offset(w * 0.92, h * 0.5),
      p,
    );
    // Center vertical (above net)
    canvas.drawLine(
      Offset(w * 0.5, h * 0.12),
      Offset(w * 0.5, h * 0.5),
      p,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.5),
      Offset(w * 0.5, h * 0.88),
      p,
    );
    // Tram lines
    final tramP = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(w * 0.18, h * 0.12), Offset(w * 0.18, h * 0.88), tramP);
    canvas.drawLine(
        Offset(w * 0.82, h * 0.12), Offset(w * 0.82, h * 0.88), tramP);

    // Net posts
    final postP = Paint()
      ..color = AppColor.kAccentYellow.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.08, h * 0.5), 4, postP);
    canvas.drawCircle(Offset(w * 0.92, h * 0.5), 4, postP);
  }

  @override
  bool shouldRepaint(_) => false;
}