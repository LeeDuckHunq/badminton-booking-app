// lib/ui/home/data/home_dummy_data.dart

import '../models/home_model.dart';

class HomeDummyData {
  // ── Quick filter chips ────────────────────────────────────────────────────────
  static const List<String> quickFilters = [
    'Cầu lông gần tôi',
    'Pickleball gần tôi',
    'Xé vé gần tôi',
  ];

  // ── Sport categories ──────────────────────────────────────────────────────────
  // Replace iconAsset with your real asset paths
  static const List<SportCategory> sportCategories = [
    SportCategory(id: 'pickleball', name: 'Pickleball',   iconAsset: 'assets/icons/ic_pickleball.png'),
    SportCategory(id: 'badminton',  name: 'Cầu lông',     iconAsset: 'assets/icons/ic_badminton.png'),
    SportCategory(id: 'football',   name: 'Bóng đá',      iconAsset: 'assets/icons/ic_football.png'),
    SportCategory(id: 'tennis',     name: 'Tennis',        iconAsset: 'assets/icons/ic_tennis.png'),
    SportCategory(id: 'volleyball', name: 'B.Chuyên',      iconAsset: 'assets/icons/ic_volleyball.png'),
    SportCategory(id: 'basketball', name: 'Bóng rổ',      iconAsset: 'assets/icons/ic_basketball.png'),
  ];

  // ── Venue list ────────────────────────────────────────────────────────────────
  static const List<Venue> venues = [
    Venue(
      id: '1',
      name: 'Pickleball Gò Mây',
      address: '133/7 Nguyễn Thị Tú, Phường Bình Tân...',
      distance: '645.3m',
      openHours: '06:00 - 22:00',
      imageAsset: 'assets/images/venue_pickleball_gomay.jpg',
      logoAsset: 'assets/logos/logo_pickleball_gomay.png',
      isBookable: true,
      isFavorited: false,
      rating: null,
      tags: [
        VenueTag(label: 'Đơn ngày', type: VenueTagType.single),
        VenueTag(label: 'Sự kiện',  type: VenueTagType.event),
      ],
    ),
    Venue(
      id: '2',
      name: 'PLATINUM BADMINTON (Trà Mi)',
      address: '463 Quốc Lộ 1A, Bình Hưng Hoà, Bình ...',
      distance: '748.1m',
      openHours: '05:00 - 07:00',
      imageAsset: 'assets/images/venue_platinum_badminton.jpg',
      logoAsset: 'assets/logos/logo_platinum.png',
      isBookable: true,
      isFavorited: false,
      rating: 5.0,
      tags: [
        VenueTag(label: '5.0',      type: VenueTagType.rating),
        VenueTag(label: 'Đơn ngày', type: VenueTagType.single),
        VenueTag(label: 'Sự kiện',  type: VenueTagType.event),
      ],
    ),
    Venue(
      id: '3',
      name: 'SmashZone Arena Q7',
      address: '88 Nguyễn Thị Thập, Tân Phú, Quận 7...',
      distance: '1.2km',
      openHours: '06:00 - 23:00',
      imageAsset: 'assets/images/venue_smashzone.jpg',
      logoAsset: 'assets/logos/logo_smashzone.png',
      isBookable: true,
      isFavorited: true,
      rating: 4.8,
      tags: [
        VenueTag(label: '4.8',      type: VenueTagType.rating),
        VenueTag(label: 'Đơn ngày', type: VenueTagType.single),
      ],
    ),
  ];
}