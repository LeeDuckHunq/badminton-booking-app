// lib/ui/booking/widgets/booking_court_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/model/san_model.dart';
import '../models/booking_state.dart';

class BookingCourtRow extends StatelessWidget {
  final SanModel san;
  final List<TimeSlot> slots;
  final Set<DateTime> selectedStarts; // starts của các slot đang selected
  final double cellWidth;
  final double rowHeight;
  final void Function(TimeSlot slot) onSlotTap;

  const BookingCourtRow({
    super.key,
    required this.san,
    required this.slots,
    required this.selectedStarts,
    required this.cellWidth,
    required this.rowHeight,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Tên sân (sticky left) ──────────────────────────────────────────
        _CourtLabel(san: san, height: rowHeight),

        // ── Các ô thời gian ────────────────────────────────────────────────
        ...slots.map((slot) {
          final isSelected = selectedStarts.contains(slot.start);
          return _SlotCell(
            slot: slot,
            isSelected: isSelected,
            width: cellWidth,
            height: rowHeight,
            onTap: () {
              HapticFeedback.lightImpact();
              onSlotTap(slot);
            },
          );
        }),
      ],
    );
  }
}

// ── Tên sân bên trái ──────────────────────────────────────────────────────────
class _CourtLabel extends StatelessWidget {
  final SanModel san;
  final double height;
  static const double width = 64;

  const _CourtLabel({required this.san, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: AppColor.kMintField,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        border: Border.all(color: Colors.green[100]!, width: 1),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_tennis_rounded,
                  color: AppColor.kCourtGreen, size: 13),
              const SizedBox(height: 1),
              Text(
                san.tenSan,
                style: const TextStyle(
                  color: AppColor.kTextDark,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                _formatGia(san.gia),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatGia(double gia) {
    if (gia >= 1000000) return '${(gia / 1000000).toStringAsFixed(1)}M/h';
    if (gia >= 1000)    return '${(gia / 1000).toStringAsFixed(0)}K/h';
    return '${gia.toStringAsFixed(0)}/h';
  }
}

// ── Ô time slot ───────────────────────────────────────────────────────────────
class _SlotCell extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _SlotCell({
    required this.slot,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = isSelected ? SlotStatus.selected : slot.status;

    return GestureDetector(
      onTap: slot.isSelectable || isSelected ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _bgColor(status),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _borderColor(status),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColor.kCourtGreen.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: _cellContent(status),
      ),
    );
  }

  Color _bgColor(SlotStatus s) {
    switch (s) {
      case SlotStatus.available: return const Color(0xFFF0FAF4);
      case SlotStatus.booked:    return const Color(0xFFFFEBEB);
      case SlotStatus.locked:    return const Color(0xFFF2F2F2);
      case SlotStatus.selected:  return const Color(0xFFD4F5E2);
    }
  }

  Color _borderColor(SlotStatus s) {
    switch (s) {
      case SlotStatus.available: return Colors.green.shade100;
      case SlotStatus.booked:    return Colors.red.shade200;
      case SlotStatus.locked:    return Colors.grey.shade300;
      case SlotStatus.selected:  return AppColor.kCourtGreen;
    }
  }

  Widget? _cellContent(SlotStatus s) {
    switch (s) {
      case SlotStatus.booked:
        return Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
        );
      case SlotStatus.selected:
        return const Center(
          child: Icon(Icons.check_rounded,
              color: AppColor.kCourtGreen, size: 12),
        );
      default:
        return null;
    }
  }
}