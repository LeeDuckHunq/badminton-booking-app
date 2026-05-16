// lib/ui/booking/widgets/booking_grid.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/model/san_model.dart';
import '../models/booking_state.dart';
import 'booking_court_row.dart';

class BookingGrid extends StatefulWidget {
  final List<SanModel> sanList;

  /// slots[maSan] = list TimeSlot của sân đó
  final Map<String, List<TimeSlot>> slotMap;

  /// Các slot đang được chọn
  final Set<DateTime> selectedStarts;
  final String? selectedMaSan;

  final void Function(TimeSlot slot) onSlotTap;

  const BookingGrid({
    super.key,
    required this.sanList,
    required this.slotMap,
    required this.selectedStarts,
    required this.selectedMaSan,
    required this.onSlotTap,
  });

  static const double cellWidth  = 44;
  static const double cellHeight = 48;
  static const double labelWidth = 64;
  static const double headerHeight = 32;

  @override
  State<BookingGrid> createState() => _BookingGridState();
}

class _BookingGridState extends State<BookingGrid> {
  final _verticalCtrl   = ScrollController();
  final _horizontalCtrl = ScrollController();

  // Để đồng bộ horizontal scroll của header và body
  final _headerHorizCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalCtrl.addListener(() {
      if (_headerHorizCtrl.hasClients &&
          _headerHorizCtrl.offset != _horizontalCtrl.offset) {
        _headerHorizCtrl.jumpTo(_horizontalCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalCtrl.dispose();
    _horizontalCtrl.dispose();
    _headerHorizCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sanList.isEmpty) return _emptyState();

    // Lấy timeline từ slots của sân đầu tiên có data
    final firstSlots = widget.slotMap.values.firstOrNull ?? [];
    if (firstSlots.isEmpty) return _emptyState();

    final timeLabels = firstSlots
        .map((s) => _formatTime(s.start))
        .toList();

    return Column(
      children: [
        // ── Time header (sticky top) ─────────────────────────────────────
        _buildTimeHeader(timeLabels),

        const Divider(height: 1, color: Color(0xFFE8EDE9)),

        // ── Grid body ────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalCtrl,
            child: SingleChildScrollView(
              controller: _horizontalCtrl,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.sanList.map((san) {
                  final slots = widget.slotMap[san.maSan] ?? [];
                  final selected = widget.selectedMaSan == san.maSan
                      ? widget.selectedStarts
                      : <DateTime>{};

                  return BookingCourtRow(
                    san: san,
                    slots: slots,
                    selectedStarts: selected,
                    cellWidth: BookingGrid.cellWidth,
                    rowHeight: BookingGrid.cellHeight,
                    onSlotTap: widget.onSlotTap,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeHeader(List<String> labels) {
    return Row(
      children: [
        // Corner spacer (aligned with court label)
        Container(
          width: BookingGrid.labelWidth,
          height: BookingGrid.headerHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FBF8),
          ),
          child: const Center(
            child: Text('Sân / Giờ',
                style: TextStyle(
                  color: AppColor.kCourtGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),

        // Scrollable time labels (synced with body)
        Expanded(
          child: SingleChildScrollView(
            controller: _headerHorizCtrl,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: labels.asMap().entries.map((entry) {
                final i     = entry.key;
                final label = entry.value;
                // Chỉ hiển thị label giờ chẵn (xx:00), :30 bỏ qua
                final showLabel = label.endsWith(':00');

                return SizedBox(
                  width: BookingGrid.cellWidth + 2, // +2 cho margin
                  height: BookingGrid.headerHeight,
                  child: showLabel
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColor.kTextDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 6,
                        color: Colors.grey[300],
                      ),
                    ],
                  )
                      : Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 1,
                      height: 4,
                      color: Colors.grey[200],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis_rounded,
              color: Colors.grey[300], size: 52),
          const SizedBox(height: 12),
          Text('Không có dữ liệu sân',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}