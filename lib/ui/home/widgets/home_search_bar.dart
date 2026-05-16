// lib/ui/home/widgets/home_search_bar.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onQrTap;
  final VoidCallback onFavoriteTap;

  const HomeSearchBar({
    super.key,
    required this.onSearchTap,
    required this.onQrTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColor.kLineWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.kDeepGreen.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // App logo mini
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColor.kMintField,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sports_tennis_rounded,
                          color: AppColor.kCourtGreen, size: 16),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Tìm kiếm',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.5,
                        ),
                      ),
                    ),

                    // QR icon
                    GestureDetector(
                      onTap: onQrTap,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.grey[400], size: 22),
                      ),
                    ),

                    // Search icon
                    GestureDetector(
                      onTap: onSearchTap,
                      child: Icon(Icons.search_rounded,
                          color: Colors.grey[400], size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Favorite button
          GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.kLineWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kDeepGreen.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: AppColor.kCourtGreen, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}