// lib/ui/screen/favorite_list_screen.dart
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/home/widgets/venue_card.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// M6 – Sân yêu thích.
class FavoriteListScreen extends StatefulWidget {
  final List<CumSanModel> courtList;
  final Map<String, String> courtImage;
  final Set<String> favMaCumSanSet;
  final Future<void> Function(String) onFavoriteTap;
  final void Function(CumSanModel) onBookTap;

  const FavoriteListScreen({super.key, required this.courtList, required this.courtImage, required this.favMaCumSanSet, required this.onFavoriteTap, required this.onBookTap});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  Future<void> _directions(CumSanModel court) async {
    final encoded = Uri.encodeComponent(court.diaChi);
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final favList = widget.courtList.where((c) => widget.favMaCumSanSet.contains(c.maCumSan)).toList();
    return Scaffold(
      appBar: SzTopBar(title: 'Sân yêu thích', subtitle: '${favList.length} cụm sân đã lưu'),
      body: favList.isEmpty
          ? SzEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Bạn chưa có sân yêu thích nào',
              message: 'Thả tim ở các cụm sân để xem lại nhanh tại đây.',
              actionLabel: 'Khám phá sân',
              onAction: () => Navigator.pop(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: favList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final court = favList[i];
                return VenueCard(
                  court: court,
                  courtImage: widget.courtImage[court.maCumSan] ?? '',
                  isFav: widget.favMaCumSanSet.contains(court.maCumSan),
                  onFavoriteTap: () async {
                    await widget.onFavoriteTap(court.maCumSan);
                    if (mounted) setState(() {});
                  },
                  onBookTap: () => widget.onBookTap(court),
                  onCardTap: () => widget.onBookTap(court),
                  onDirectionTap: () => _directions(court),
                );
              },
            ),
    );
  }
}
