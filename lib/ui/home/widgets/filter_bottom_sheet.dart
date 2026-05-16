// lib/ui/home/widgets/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import '../models/filter_model.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterModel initialFilter;
  final ValueChanged<FilterModel> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required FilterModel currentFilter,
    required ValueChanged<FilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late int? _openBeforeHour;
  late int? _closeAfterHour;

  // Các preset giờ mở cửa có thể chọn
  static const _openOptions = [5, 6, 7, 8];

  // Các preset giờ đóng cửa có thể chọn
  static const _closeOptions = [21, 22, 23, 24];

  @override
  void initState() {
    super.initState();
    _openBeforeHour  = widget.initialFilter.openBeforeHour;
    _closeAfterHour  = widget.initialFilter.closeAfterHour;
  }

  bool get _hasChanges =>
      _openBeforeHour != widget.initialFilter.openBeforeHour ||
          _closeAfterHour != widget.initialFilter.closeAfterHour;

  bool get _isEmpty => _openBeforeHour == null && _closeAfterHour == null;

  void _reset() => setState(() {
    _openBeforeHour = null;
    _closeAfterHour = null;
  });

  void _apply() {
    widget.onApply(FilterModel(
      openBeforeHour: _openBeforeHour,
      closeAfterHour: _closeAfterHour,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.kMintField,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppColor.kCourtGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lọc sân',
                style: TextStyle(
                  color: AppColor.kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (!_isEmpty)
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.red[400], size: 14),
                        const SizedBox(width: 4),
                        Text('Xoá bộ lọc',
                            style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── Section: Giờ mở cửa ───────────────────────────────────────
          _SectionLabel(
            icon: Icons.wb_sunny_outlined,
            label: 'Mở cửa trước',
            subtitle: _openBeforeHour != null
                ? 'trước ${_openBeforeHour}:00'
                : 'Chưa chọn',
            hasValue: _openBeforeHour != null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _openOptions.map((h) {
              final selected = _openBeforeHour == h;
              return _TimeChip(
                label: '$h:00',
                selected: selected,
                onTap: () => setState(() {
                  _openBeforeHour = selected ? null : h;
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── Section: Giờ đóng cửa ─────────────────────────────────────
          _SectionLabel(
            icon: Icons.nights_stay_outlined,
            label: 'Đóng cửa sau',
            subtitle: _closeAfterHour != null
                ? 'sau ${_closeAfterHour == 24 ? '23:59' : '$_closeAfterHour:00'}'
                : 'Chưa chọn',
            hasValue: _closeAfterHour != null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _closeOptions.map((h) {
              final selected = _closeAfterHour == h;
              return _TimeChip(
                label: h == 24 ? '23:59' : '$h:00',
                selected: selected,
                onTap: () => setState(() {
                  _closeAfterHour = selected ? null : h;
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Active filters summary ────────────────────────────────────
          if (!_isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.kMintField,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded,
                      color: AppColor.kCourtGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildSummary(),
                      style: const TextStyle(
                        color: AppColor.kCourtGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Apply button ──────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kCourtGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _isEmpty ? 'Xem tất cả sân' : 'Áp dụng bộ lọc',
                style: const TextStyle(
                  color: AppColor.kLineWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummary() {
    final parts = <String>[];
    if (_openBeforeHour != null) {
      parts.add('Mở cửa trước $_openBeforeHour:00');
    }
    if (_closeAfterHour != null) {
      final label = _closeAfterHour == 24 ? '23:59' : '$_closeAfterHour:00';
      parts.add('Đóng cửa sau $label');
    }
    return parts.join(' • ');
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool hasValue;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: hasValue ? AppColor.kCourtGreen : Colors.grey[500],
            size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColor.kTextDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: hasValue ? AppColor.kCourtGreen : Colors.grey[400],
            fontSize: 12,
            fontWeight:
            hasValue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColor.kCourtGreen : const Color(0xFFF4F6F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColor.kCourtGreen : Colors.grey[300]!,
            width: 1.4,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColor.kCourtGreen.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  color: AppColor.kLineWhite, size: 13),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColor.kLineWhite : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}