// lib/ui/home/widgets/filter_bottom_sheet.dart
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

import '../models/filter_model.dart';

/// M4 – Bộ lọc giờ mở / đóng cửa.
class FilterBottomSheet extends StatefulWidget {
  final FilterModel initialFilter;
  final ValueChanged<FilterModel> onApply;

  const FilterBottomSheet({super.key, required this.initialFilter, required this.onApply});

  static Future<void> show({required BuildContext context, required FilterModel currentFilter, required ValueChanged<FilterModel> onApply}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(initialFilter: currentFilter, onApply: onApply),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late int? _openBefore = widget.initialFilter.openBeforeHour;
  late int? _closeAfter = widget.initialFilter.closeAfterHour;

  static const _openMin = 4, _openMax = 12;
  static const _closeMin = 18, _closeMax = 24;

  void _apply() {
    widget.onApply(FilterModel(openBeforeHour: _openBefore, closeAfterHour: _closeAfter));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SzSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(children: [
            Expanded(child: Text('Bộ lọc tìm kiếm', style: AppText.headlineMd())),
            SzIconButton(Icons.close_rounded, color: AppColor.textMuted, onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Lọc cụm sân theo giờ mở & đóng cửa phù hợp với lịch của bạn', style: AppText.body(color: AppColor.textMuted)),
                  ]),
                ),
                const SizedBox(width: 12),
                SzButton.small('Mặc định', icon: Icons.restart_alt_rounded, kind: SzButtonKind.soft, onPressed: () => setState(() => _openBefore = _closeAfter = null)),
              ]),
              const SizedBox(height: 16),
              _TimeSection(
                icon: Icons.wb_twilight_rounded,
                title: 'Mở cửa trước',
                description: 'Phù hợp đánh trận sáng sớm trước giờ làm',
                value: _openBefore,
                suffix: 'SÁNG',
                min: _openMin,
                max: _openMax,
                presets: const [(6, 'Trước 06:00', Icons.wb_twilight_rounded), (7, 'Trước 07:00', Icons.light_mode_outlined), (8, 'Trước 08:00', Icons.light_mode_rounded), (null, 'Tất cả giờ mở', Icons.all_inclusive_rounded)],
                labelFor: (h) => 'Trước ${Fmt.two(h)}:00',
                onChanged: (v) => setState(() => _openBefore = v),
              ),
              const SizedBox(height: 16),
              _TimeSection(
                icon: Icons.nightlight_round,
                iconBg: const Color(0xFFFFF4B8),
                title: 'Đóng cửa sau',
                description: 'Thoải mái giao lưu buổi tối, đánh khuya',
                value: _closeAfter,
                suffix: 'TỐI',
                min: _closeMin,
                max: _closeMax,
                presets: const [(21, 'Sau 21:00', Icons.schedule_rounded), (22, 'Sau 22:00', Icons.nights_stay_outlined), (23, 'Sau 23:00', Icons.bedtime_outlined), (24, 'Mở đến 24:00', Icons.auto_awesome_outlined)],
                labelFor: (h) => h == 24 ? 'Đến 24:00' : 'Sau ${Fmt.two(h)}:00',
                onChanged: (v) => setState(() => _closeAfter = v),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
          child: Row(children: [
            SzButton('Thiết lập lại', kind: SzButtonKind.ghost, onPressed: () => setState(() => _openBefore = _closeAfter = null)),
            const SizedBox(width: 8),
            Expanded(child: SzButton('Áp dụng bộ lọc', trailingIcon: Icons.check_rounded, onPressed: _apply)),
          ]),
        ),
      ]),
    );
  }
}

class _TimeSection extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String description;
  final int? value;
  final String suffix;
  final int min;
  final int max;
  final List<(int?, String, IconData)> presets;
  final String Function(int) labelFor;
  final ValueChanged<int?> onChanged;

  const _TimeSection({
    required this.icon,
    this.iconBg = const Color(0xFFB2F2BA),
    required this.title,
    required this.description,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.presets,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: AppColor.primaryDark, size: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.headlineSm()),
              Text(description, style: AppText.bodySm()),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: value == null
                ? Text('Mọi giờ', style: AppText.headlineSm(color: AppColor.primaryDark))
                : Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${Fmt.two(value!)}:00', style: AppText.stat(size: 26, color: AppColor.primaryDark)),
                    const SizedBox(width: 4),
                    Text(suffix, style: AppText.labelSm(color: AppColor.text)),
                  ]),
          ),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.4,
          children: [
            for (final (hour, label, presetIcon) in presets)
              _PresetTile(label: label, icon: presetIcon, selected: value == hour, onTap: () => onChanged(hour)),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          _StepButton(Icons.remove_rounded, onTap: () => onChanged(((value ?? max) - 1).clamp(min, max))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: const Color(0xFFB4E8BC),
                inactiveTrackColor: const Color(0xFFC6ECCA),
                thumbColor: AppColor.primaryDark,
                overlayColor: AppColor.primary.withValues(alpha: 0.12),
                showValueIndicator: ShowValueIndicator.onDrag,
                valueIndicatorColor: AppColor.primaryDark,
              ),
              child: Slider(
                value: (value ?? max).toDouble().clamp(min.toDouble(), max.toDouble()),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: labelFor(value ?? max),
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          _StepButton(Icons.add_rounded, onTap: () => onChanged(((value ?? min) + 1).clamp(min, max))),
        ]),
      ]),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primaryDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(child: Text(label, style: AppText.labelLg(color: selected ? Colors.white : AppColor.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
            Icon(selected ? Icons.check_circle_outline_rounded : icon, size: 20, color: selected ? Colors.white : AppColor.textMuted),
          ]),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: SizedBox(width: 48, height: 48, child: Icon(icon, color: AppColor.text))),
    );
  }
}
