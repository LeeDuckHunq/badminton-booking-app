// lib/ui/booking/widgets/booking_date_picker.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class BookingDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  /// Số ngày hiển thị (trước + sau hôm nay)
  final int dayRange;

  const BookingDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.dayRange = 14,
  });

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _months   = [
    '', 'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
    'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
      dayRange,
          (i) => DateTime(today.year, today.month, today.day + i),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            '${_months[selectedDate.month]} ${selectedDate.year}',
            style: const TextStyle(
              color: AppColor.kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Horizontal date strip
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final date      = dates[i];
              final isSelected = _isSameDay(date, selectedDate);
              final isToday    = _isSameDay(date, today);
              final weekday    = _weekdays[date.weekday - 1];

              return GestureDetector(
                onTap: () => onDateChanged(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.kCourtGreen
                        : AppColor.kLineWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColor.kCourtGreen
                          : isToday
                          ? AppColor.kCourtGreen.withOpacity(0.4)
                          : Colors.grey[200]!,
                      width: isToday && !isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColor.kCourtGreen.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekday,
                        style: TextStyle(
                          color: isSelected
                              ? AppColor.kLineWhite.withOpacity(0.8)
                              : Colors.grey[500],
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColor.kLineWhite
                              : AppColor.kTextDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isToday && !isSelected)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: AppColor.kCourtGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}