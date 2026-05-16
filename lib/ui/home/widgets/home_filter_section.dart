// lib/ui/home/widgets/home_filter_section.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import '../models/home_model.dart';

// ─── Quick Filter Chips ───────────────────────────────────────────────────────

class QuickFilterChips extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final ValueChanged<String> onSelected;

  const QuickFilterChips({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColor.kCourtGreen : AppColor.kLineWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColor.kCourtGreen
                      : Colors.grey[300]!,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColor.kCourtGreen.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? AppColor.kLineWhite : Colors.grey[700],
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}