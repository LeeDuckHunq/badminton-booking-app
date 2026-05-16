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

// ─── Sport Category List ──────────────────────────────────────────────────────

class SportCategoryList extends StatelessWidget {
  final List<SportCategory> categories;
  final String? selectedId;
  final ValueChanged<SportCategory> onSelected;

  const SportCategoryList({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = selectedId == cat.id;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: SizedBox(
              width: 66,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.kCourtGreen
                          : AppColor.kLineWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColor.kCourtGreen
                            : Colors.grey[200]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColor.kCourtGreen.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        cat.iconAsset,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.sports_tennis_rounded,
                          color: isSelected
                              ? AppColor.kLineWhite
                              : AppColor.kCourtGreen,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cat.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColor.kCourtGreen
                          : Colors.grey[700],
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}