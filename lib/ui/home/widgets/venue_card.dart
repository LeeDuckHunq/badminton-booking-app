// lib/ui/home/widgets/venue_card.dart
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/review/review_widgets.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// Card cụm sân dùng ở Trang chủ, Tìm kiếm, Yêu thích.
class VenueCard extends StatelessWidget {
  final CumSanModel court;
  final String courtImage;
  final String? distance;
  final bool isLoadingDistance;
  final VoidCallback onBookTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onDirectionTap;
  final VoidCallback onCardTap;
  final bool isFav;

  const VenueCard({
    super.key,
    this.isFav = false,
    required this.court,
    required this.courtImage,
    this.distance,
    this.isLoadingDistance = false,
    required this.onBookTap,
    required this.onFavoriteTap,
    required this.onDirectionTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SzCard(
        padding: EdgeInsets.zero,
        onTap: onCardTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              SzNetworkImage(courtImage),
              if (court.diemDanhGia != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: RatingPill(score: court.diemDanhGia, count: court.soDanhGia, onTap: () => showVenueReviewsSheet(context, court)),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Row(children: [
                  if (distance != null)
                    _OverlayPill(icon: Icons.near_me_rounded, text: distance!)
                  else if (isLoadingDistance)
                    const _OverlayPill(icon: Icons.near_me_rounded, text: '…'),
                  if (court.soSan > 0) ...[
                    const SizedBox(width: 6),
                    _OverlayPill(text: '${court.soSan} sân', mint: true),
                  ],
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(court.tenCumSan, style: AppText.headlineSm(color: AppColor.forest).copyWith(fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              _MetaLine(icon: Icons.location_on_outlined, text: court.diaChi),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: _MetaLine(icon: Icons.schedule_rounded, text: Fmt.hours(court.gioMoCua, court.gioDongCua))),
                if (court.soSan > 0) _MetaLine(icon: Icons.check_circle_outline_rounded, text: '${court.soSan} sân sẵn sàng', color: AppColor.primary),
              ]),
            ]),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 0), child: Divider()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
            child: Row(children: [
              Expanded(
                child: court.giaTu == null
                    ? Text('Chưa có giá', style: AppText.body(color: AppColor.textMuted))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('GIÁ CHỈ TỪ', style: AppText.labelSm()),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: Fmt.money(court.giaTu!), style: AppText.stat(size: 22, color: AppColor.primaryDark)),
                            TextSpan(text: ' /giờ', style: AppText.bodySm()),
                          ])),
                        ),
                      ]),
              ),
              _RoundAction(icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? AppColor.danger : AppColor.textMuted, onTap: onFavoriteTap, tooltip: isFav ? 'Bỏ yêu thích' : 'Yêu thích'),
              const SizedBox(width: 8),
              _RoundAction(icon: Icons.directions_rounded, color: AppColor.primary, onTap: onDirectionTap, tooltip: 'Chỉ đường'),
              const SizedBox(width: 8),
              SzButton.small('Đặt sân', kind: SzButtonKind.dark, trailingIcon: Icons.arrow_forward_rounded, onPressed: onBookTap),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final bool mint;
  const _OverlayPill({this.icon, required this.text, this.mint = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: mint ? const Color(0xFFB2F2BA) : Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: AppColor.primaryDark), const SizedBox(width: 4)],
        Text(text, style: AppText.label(color: AppColor.primaryDark)),
      ]),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetaLine({required this.icon, required this.text, this.color = AppColor.textMuted});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: AppText.body(color: color == AppColor.textMuted ? AppColor.textMuted : color), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _RoundAction({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppColor.border)),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: color))),
      ),
    );
  }
}
