// lib/ui/home/widgets/promo_banner.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class PromoBanner extends StatelessWidget {
  final String text;
  final VoidCallback onFilterTap;

  const PromoBanner({
    super.key,
    this.text = 'Tìm sân trống, sự kiện xé vé, ghép đội',
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFFB74D).withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            // Orange sport icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_basketball_rounded,
                  color: Colors.white, size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // Filter icon
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColor.kCourtGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColor.kCourtGreen,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}