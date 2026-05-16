// lib/ui/home/models/home_model.dart

class SportCategory {
  final String id;
  final String name;
  final String iconAsset; // e.g. 'assets/icons/ic_badminton.png'

  const SportCategory({
    required this.id,
    required this.name,
    required this.iconAsset,
  });
}

class VenueTag {
  final String label;
  final VenueTagType type;

  const VenueTag({required this.label, required this.type});
}

enum VenueTagType { rating, single, event }

class Venue {
  final String id;
  final String name;
  final String address;
  final String distance;       // e.g. "645.3m"
  final String openHours;      // e.g. "06:00 - 22:00"
  final String imageAsset;     // court photo
  final String logoAsset;      // venue logo
  final List<VenueTag> tags;
  final bool isBookable;
  final bool isFavorited;
  final double? rating;        // null = no rating shown

  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.openHours,
    required this.imageAsset,
    required this.logoAsset,
    required this.tags,
    this.isBookable = true,
    this.isFavorited = false,
    this.rating,
  });
}