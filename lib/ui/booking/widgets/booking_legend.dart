// lib/ui/booking/widgets/booking_legend.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class BookingLegend extends StatelessWidget {
  const BookingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _LegendItem(color: const Color(0xFFF0FAF4),
              border: Colors.green.shade100, label: 'Trống'),
          const SizedBox(width: 12),
          _LegendItem(color: const Color(0xFFD4F5E2),
              border: AppColor.kCourtGreen, label: 'Đang chọn'),
          const SizedBox(width: 12),
          _LegendItem(color: const Color(0xFFFFEBEB),
              border: Colors.red.shade200, label: 'Đã đặt'),
          const SizedBox(width: 12),
          _LegendItem(color: const Color(0xFFF2F2F2),
              border: Colors.grey.shade300, label: 'Khoá'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;

  const _LegendItem({
    required this.color,
    required this.border,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border, width: 1.2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}