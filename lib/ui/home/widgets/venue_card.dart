// lib/ui/home/widgets/venue_card.dart

import 'package:application/model/cum_san_model.dart';
import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class VenueCard extends StatefulWidget {
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
    this.isFav = false,
    super.key,
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
  State<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<VenueCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCardTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColor.kCardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: widget.courtImage.isNotEmpty
                ? Image.network(
              widget.courtImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),

          // Gradient overlay
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                ),
              ),
            ),
          ),

          // Tags top-left
          Positioned(
            top: 10, left: 10,
            child: Row(
              children: [
                _StarBadge(),
                const SizedBox(width: 6),
                const _TagChip(label: 'Đơn ngày', color: AppColor.kCourtGreen),
                const SizedBox(width: 6),
                const _TagChip(label: 'Sự kiện', color: Color(0xFFE91E8C)),
              ],
            ),
          ),

          // Fav + direction top-right
          Positioned(
            top: 8, right: 8,
            child: Row(
              children: [
                _CircleBtn(
                  icon: widget.isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: widget.isFav ? Colors.redAccent : Colors.grey[600]!,
                  onTap: () => widget.onFavoriteTap(),
                ),
                const SizedBox(width: 6),
                _CircleBtn(
                  icon: Icons.near_me_outlined,
                  color: Colors.grey[700]!,
                  onTap: widget.onDirectionTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.kMintField,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[100]!, width: 1),
            ),
            child: const Icon(Icons.sports_tennis_rounded,
                color: AppColor.kCourtGreen, size: 24),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên sân
                Text(
                  widget.court.tenCumSan,
                  style: const TextStyle(
                    color: AppColor.kTextDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Khoảng cách + địa chỉ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildDistanceBadge(),
                    if (widget.distance != null || widget.isLoadingDistance)
                      const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.court.diaChi,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Giờ hoạt động
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.court.gioMoCua} - ${widget.court.gioDongCua}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          _BookButton(onTap: widget.onBookTap),
        ],
      ),
    );
  }

  /// Spinner khi đang tính | badge khi có | ẩn khi null
  Widget _buildDistanceBadge() {
    if (widget.isLoadingDistance) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          color: AppColor.kCourtGreen,
          strokeWidth: 1.5,
        ),
      );
    }

    if (widget.distance == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.kMintField,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 10, color: AppColor.kCourtGreen),
          const SizedBox(width: 3),
          Text(
            widget.distance!,
            style: const TextStyle(
              color: AppColor.kCourtGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A6B3C),
    child: const Center(
      child: Icon(Icons.sports_tennis_rounded, color: Colors.white38, size: 48),
    ),
  );
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StarBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BookButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColor.kAccentYellow,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: AppColor.kAccentYellow.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Text(
          'ĐẶT LỊCH',
          style: TextStyle(
            color: AppColor.kDeepGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}