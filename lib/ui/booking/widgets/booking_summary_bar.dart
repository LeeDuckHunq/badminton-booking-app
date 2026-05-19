import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import '../models/booking_state.dart';

class BookingSummaryBar extends StatelessWidget {
  final BookingSelection? selection;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  const BookingSummaryBar({
    super.key,
    required this.selection,
    required this.onConfirm,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: selection != null ? 90 : 0,
      child: selection != null
          ? _buildContent(context, selection!)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, BookingSelection sel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.kLineWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // ── Info ──────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_tennis_rounded,
                        color: AppColor.kCourtGreen, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      sel.san.tenSan,
                      style: const TextStyle(
                        color: AppColor.kTextDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.kMintField,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.green[200]!, width: 1),
                      ),
                      child: Text(
                        sel.thoiGianHienThi,
                        style: const TextStyle(
                          color: AppColor.kCourtGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '${_formatHours(sel.tongGio)} giờ',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: _formatCurrency(sel.tongTien),
                      highlight: true,
                    ),
                    const Spacer(),
                    // Clear button
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close_rounded,
                            color: Colors.grey[500], size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Confirm button ─────────────────────────────────────────────
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kCourtGreen.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'ĐẶT SÂN',
                style: TextStyle(
                  color: AppColor.kLineWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double h) {
    if (h == h.truncate()) return h.truncate().toString();
    return h.toStringAsFixed(1);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M đ';
    }
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColor.kAccentYellow.withOpacity(0.15)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? AppColor.kAccentYellow.withOpacity(0.5)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: highlight ? const Color(0xFFF57F17) : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFFF57F17) : Colors.grey[700],
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}