// lib/ui/screen/favorite_list_screen.dart

import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/home/widgets/venue_card.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';

class FavoriteListScreen extends StatelessWidget {
  final List<CumSanModel> courtList;
  final Map<String, String> courtImage;
  final Set<String> favMaCumSanSet;
  final Function(String) onFavoriteTap;
  final Function(CumSanModel) onBookTap;

  const FavoriteListScreen({
    super.key,
    required this.courtList,
    required this.courtImage,
    required this.favMaCumSanSet,
    required this.onFavoriteTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final favList = courtList
        .where((c) => favMaCumSanSet.contains(c.maCumSan))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: AppColor.kCourtGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Sân yêu thích',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: favList.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                color: Colors.grey, size: 56),
            SizedBox(height: 12),
            Text(
              'Chưa có sân yêu thích nào',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: favList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final court = favList[i];
          return VenueCard(
            court: court,
            courtImage: courtImage[court.maCumSan] ?? '',
            isFav: true,
            onFavoriteTap: () => onFavoriteTap(court.maCumSan),
            onBookTap: () => onBookTap(court),
            onDirectionTap: () {},
            onCardTap: () => onBookTap(court),
          );
        },
      ),
    );
  }
}