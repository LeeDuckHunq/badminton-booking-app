import 'package:flutter/material.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/theme/app_color.dart';

class VoucherCard extends StatefulWidget {
  final KhuyenMaiModel voucher;
  final bool isClaiming;
  final VoidCallback onClaim;
  final int index;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.isClaiming,
    required this.onClaim,
    required this.index,
  });

  @override
  State<VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<VoucherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 80),
    )..forward();
    _fadeSlide =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  int get _daysLeft =>
      widget.voucher.ngayKetThuc.difference(DateTime.now()).inDays;

  @override
  Widget build(BuildContext context) {
    final v = widget.voucher;
    final pct = (v.phanTramGiam * 100).toStringAsFixed(0);
    final days = _daysLeft;
    final isUrgent = days <= 3;

    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(v, pct, days, isUrgent),
                _DashedDivider(),
                _buildBottom(v, isUrgent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Widget _buildBanner(
      KhuyenMaiModel v, String pct, int days, bool isUrgent) {
    return Stack(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Image.network(
            v.duongDanAnh,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColor.kDeepGreen,
              child: const Icon(Icons.image_not_supported_rounded,
                  color: Colors.white38, size: 36),
            ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Discount badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.kAccentYellow,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kAccentYellow.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    color: AppColor.kDeepGreen, size: 14),
                const SizedBox(width: 3),
                Text(
                  'GIẢM $pct%',
                  style: const TextStyle(
                    color: AppColor.kDeepGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Urgent badge
        if (isUrgent)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    days == 0 ? 'Hôm nay!' : 'Còn $days ngày',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Tên voucher
        Positioned(
          bottom: 10,
          left: 12,
          right: 12,
          child: Text(
            v.tenKhuyenMai,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Info + CTA ────────────────────────────────────────────────────────────
  Widget _buildBottom(KhuyenMaiModel v, bool isUrgent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateRow(Icons.calendar_today_rounded,
                    'Từ ${_fmt(v.ngayBatDau)}', false),
                const SizedBox(height: 3),
                _dateRow(Icons.event_rounded,
                    'Đến ${_fmt(v.ngayKetThuc)}', isUrgent),
                const SizedBox(height: 6),
                Text(
                  v.maKhuyenMai,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ClaimButton(
            isClaiming: widget.isClaiming,
            onTap: widget.onClaim,
          ),
        ],
      ),
    );
  }

  Widget _dateRow(IconData icon, String text, bool urgent) {
    return Row(
      children: [
        Icon(icon,
            size: 11,
            color: urgent ? Colors.red[400] : Colors.grey[400]),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: urgent ? Colors.red[600] : Colors.grey[500],
            fontSize: 11.5,
            fontWeight:
            urgent ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── Claim button với pulse animation ─────────────────────────────────────────
class _ClaimButton extends StatefulWidget {
  final bool isClaiming;
  final VoidCallback onTap;
  const _ClaimButton({required this.isClaiming, required this.onTap});

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isClaiming) {
      return Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColor.kCourtGreen),
        ),
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColor.kCourtGreen.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColor.kAccentYellow, size: 16),
              SizedBox(width: 6),
              Text(
                'LẤY\nNGAY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed divider kiểu ticket ────────────────────────────────────────────────
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F4),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          Expanded(child: CustomPaint(painter: _DashPainter())),
          Container(
            width: 12,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 8.0, gap = 5.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}