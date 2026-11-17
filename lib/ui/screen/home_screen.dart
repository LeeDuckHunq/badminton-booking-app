// lib/ui/screen/home_screen.dart
import 'package:application/api/FavoriteApi.dart';
import 'package:application/api/account_api.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/services/distance_service.dart';
import 'package:application/ui/screen/ClaimVoucherScreen.dart';
import 'package:application/ui/screen/account_screen.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/screen/chat_screen.dart';
import 'package:application/ui/screen/favorite_list_screen.dart';
import 'package:application/ui/screen/highlight_screen.dart';
import 'package:application/ui/screen/search_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/models/filter_model.dart';
import '../home/widgets/filter_bottom_sheet.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/venue_card.dart';

/// Khung chính sau khi đăng nhập: 5 tab + tab Trang chủ (M3).
class HomeScreen extends StatefulWidget {
  final HomeNavTab initialTab;

  const HomeScreen({super.key, this.initialTab = HomeNavTab.home});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeNavTab _currentTab = widget.initialTab;

  String _userName = '';
  String _fullName = '';

  List<CumSanModel> courtList = [];
  Map<String, String> courtImage = {};
  final Map<String, String> _distanceMap = {};

  bool _isLoadingCourts = true;
  bool _loadFailed = false;
  bool _isLoadingDistances = false;
  Position? _userPosition;

  Set<String> _favMaCumSanSet = {};
  Map<String, String> _favMaFavMap = {};

  FilterModel _filter = const FilterModel();
  bool _sortByDistance = false;

  // ── Dữ liệu ───────────────────────────────────────────────────────────────

  List<CumSanModel> get _visibleList {
    var list = courtList.where((court) {
      final openHour = _parseHour(court.gioMoCua);
      final closeHour = _parseHour(court.gioDongCua);
      if (_filter.openBeforeHour != null && openHour > _filter.openBeforeHour!) return false;
      if (_filter.closeAfterHour != null) {
        final threshold = _filter.closeAfterHour == 24 ? 23 : _filter.closeAfterHour!;
        if (closeHour < threshold) return false;
      }
      return true;
    }).toList();
    if (_sortByDistance) {
      list.sort((a, b) => _distanceMeters(a).compareTo(_distanceMeters(b)));
    }
    return list;
  }

  int _parseHour(String t) => int.tryParse(t.split(':').first) ?? 0;

  /// "2,4 km" → 2400; "350 m" → 350; không có → rất lớn.
  double _distanceMeters(CumSanModel c) {
    final raw = _distanceMap[c.maCumSan];
    if (raw == null) return double.infinity;
    final number = double.tryParse(RegExp(r'[\d.,]+').firstMatch(raw)?.group(0)?.replaceAll('.', '').replaceAll(',', '.') ?? '');
    if (number == null) return double.infinity;
    return raw.contains('km') ? number * 1000 : number;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    if (!mounted) return;
    setState(() => _userName = username);
    _loadFavorites();
    if (username.isEmpty) return;
    try {
      final user = await AccountApi.getUser(username);
      if (mounted) setState(() => _fullName = user.fullName);
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    if (_userName.isEmpty) return;
    final map = await FavoriteApi.getFavorites(_userName);
    if (!mounted) return;
    setState(() {
      _favMaFavMap = map;
      _favMaCumSanSet = map.keys.toSet();
    });
  }

  Future<void> _toggleFavorite(String maCumSan) async {
    if (_userName.isEmpty) return;
    if (_favMaCumSanSet.contains(maCumSan)) {
      final maFav = _favMaFavMap[maCumSan];
      if (maFav == null) return;
      setState(() {
        _favMaCumSanSet.remove(maCumSan);
        _favMaFavMap.remove(maCumSan);
      });
      final ok = await FavoriteApi.deleteFavorite(maFav);
      if (!ok && mounted) {
        setState(() {
          _favMaCumSanSet.add(maCumSan);
          _favMaFavMap[maCumSan] = maFav;
        });
        showSzSnack(context, 'Không bỏ yêu thích được, thử lại nhé', type: SzToast.error);
      }
    } else {
      setState(() => _favMaCumSanSet.add(maCumSan));
      final ok = await FavoriteApi.addFavorite(_userName, maCumSan);
      if (!mounted) return;
      if (ok) {
        await _loadFavorites();
      } else {
        setState(() => _favMaCumSanSet.remove(maCumSan));
        showSzSnack(context, 'Không thêm yêu thích được, thử lại nhé', type: SzToast.error);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingCourts = true;
      _loadFailed = false;
    });
    final results = await Future.wait([
      CumSanApi.getCumSan(1000),
      HinhAnhSanApi.getAllHinhAnhSan(),
      DistanceService.getCurrentPosition(),
    ]);
    if (!mounted) return;
    final courts = results[0] as List<CumSanModel>?;
    setState(() {
      _loadFailed = courts == null;
      courtList = courts ?? [];
      courtImage = results[1] as Map<String, String>;
      _userPosition = results[2] as Position?;
      _isLoadingCourts = false;
    });
    if (_userPosition != null && courtList.isNotEmpty) await _loadDistances();
  }

  Future<void> _loadDistances() async {
    setState(() => _isLoadingDistances = true);
    final distances = await DistanceService.getDistanceBatch(
      originLat: _userPosition!.latitude,
      originLng: _userPosition!.longitude,
      destinationAddresses: courtList.map((c) => c.diaChi).toList(),
    );
    if (!mounted) return;
    for (int i = 0; i < courtList.length && i < distances.length; i++) {
      if (distances[i] != null) _distanceMap[courtList[i].maCumSan] = distances[i]!;
    }
    setState(() => _isLoadingDistances = false);
  }

  // ── Điều hướng ────────────────────────────────────────────────────────────

  void _goToBooking(CumSanModel court) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScheduleScreen(cumSan: court)));

  void _openSearch() => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(courtList: courtList, courtImage: courtImage)));

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoriteListScreen(courtList: courtList, courtImage: courtImage, favMaCumSanSet: _favMaCumSanSet, onFavoriteTap: _toggleFavorite, onBookTap: _goToBooking),
      ),
    ).then((_) => setState(() {}));
  }

  void _openFilter() => FilterBottomSheet.show(context: context, currentFilter: _filter, onApply: (f) => setState(() => _filter = f));

  Future<void> _openDirections(CumSanModel court) async {
    final encoded = Uri.encodeComponent(court.diaChi);
    final geo = Uri.parse('geo:0,0?q=$encoded');
    final web = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleNearest() {
    if (_distanceMap.isEmpty) {
      showSzSnack(context, 'Bật định vị để sắp xếp theo khoảng cách', type: SzToast.info);
      if (_userPosition == null) _loadData();
      return;
    }
    setState(() => _sortByDistance = !_sortByDistance);
  }

  // ── Giao diện ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          _buildHomeTab(),
          const ChatScreen(),
          const ClaimVoucherScreen(),
          const HighlightScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(currentTab: _currentTab, onTabChanged: (tab) => setState(() => _currentTab = tab)),
    );
  }

  Widget _buildHomeTab() {
    final list = _visibleList;
    final displayName = _fullName.isNotEmpty ? _fullName : _userName;
    // Tên gọi tiếng Việt: 2 chữ cuối với họ tên ≥ 3 chữ ("Nguyễn Tuấn Anh" → "Tuấn Anh").
    final words = displayName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final firstName = words.length >= 3 ? words.sublist(words.length - 2).join(' ') : (words.isEmpty ? '' : words.last);
    final now = DateTime.now();

    return Column(children: [
      SzBrandHeader(
        subtitle: 'Trang chủ',
        userName: displayName,
        onAvatarTap: () => setState(() => _currentTab = HomeNavTab.account),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData();
            await _loadFavorites();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColor.primary),
                    const SizedBox(width: 6),
                    Text('Hôm nay, ${Fmt.date(now)}', style: AppText.label(color: AppColor.textMuted)),
                  ]),
                  const SizedBox(height: 2),
                  Text(firstName.isEmpty ? 'Chào bạn 👋' : 'Chào $firstName 👋', style: AppText.display(color: AppColor.text).copyWith(fontSize: 26)),
                ]),
              ),
              const SizedBox(height: 14),
              _buildSearchRow(),
              const SizedBox(height: 16),
              _PromoBanner(onFilterTap: _openFilter),
              const SizedBox(height: 16),
              _buildQuickChips(),
              if (!_filter.isEmpty) _buildActiveFilter(list.length),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                child: Row(children: [
                  Text(_sortByDistance ? 'Gần bạn nhất' : 'Cụm sân', style: AppText.headlineMd()),
                  const SizedBox(width: 8),
                  if (!_isLoadingCourts) SzPill('${list.length} cụm sân'),
                  const Spacer(),
                  TextButton(onPressed: _openSearch, child: Text('Xem tất cả', style: AppText.labelLg(color: AppColor.primary))),
                ]),
              ),
              if (_isLoadingCourts)
                ..._buildSkeletons()
              else if (_loadFailed)
                SzErrorState(message: 'Không tải được danh sách sân. Kiểm tra kết nối mạng.', onRetry: _loadData)
              else if (list.isEmpty)
                SzEmptyState(
                  icon: _filter.isEmpty ? Icons.sports_tennis_rounded : Icons.filter_alt_off_rounded,
                  title: 'Không tìm thấy sân phù hợp',
                  message: _filter.isEmpty ? 'Hiện chưa có cụm sân nào hoạt động.' : 'Thử nới bộ lọc giờ mở / đóng cửa.',
                  actionLabel: _filter.isEmpty ? null : 'Xoá bộ lọc',
                  onAction: () => setState(() => _filter = const FilterModel()),
                )
              else
                for (final court in list) ...[
                  VenueCard(
                    court: court,
                    courtImage: courtImage[court.maCumSan] ?? '',
                    distance: _distanceMap[court.maCumSan],
                    isLoadingDistance: _isLoadingDistances && !_distanceMap.containsKey(court.maCumSan),
                    isFav: _favMaCumSanSet.contains(court.maCumSan),
                    onBookTap: () => _goToBooking(court),
                    onCardTap: () => _goToBooking(court),
                    onFavoriteTap: () => _toggleFavorite(court.maCumSan),
                    onDirectionTap: () => _openDirections(court),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: _openSearch,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColor.border)),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: AppColor.textMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Tìm sân theo tên hoặc địa chỉ…', style: AppText.bodyLg(color: AppColor.textSubtle), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: _openFavorites,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColor.border)),
              child: Icon(_favMaCumSanSet.isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded, color: AppColor.danger),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SzChip('Gần bạn nhất', icon: Icons.near_me_rounded, selected: _sortByDistance, onTap: _toggleNearest),
          const SizedBox(width: 8),
          SzChip('Mở trước 06:00', icon: Icons.schedule_rounded, selected: _filter.openBeforeHour == 6, onTap: () => setState(() => _filter = _filter.openBeforeHour == 6 ? _filter.copyWith(clearOpen: true) : _filter.copyWith(openBeforeHour: 6))),
          const SizedBox(width: 8),
          SzChip('Đóng sau 22:00', icon: Icons.nights_stay_outlined, selected: _filter.closeAfterHour == 22, onTap: () => setState(() => _filter = _filter.closeAfterHour == 22 ? _filter.copyWith(clearClose: true) : _filter.copyWith(closeAfterHour: 22))),
          const SizedBox(width: 8),
          SzChip('Bộ lọc', icon: Icons.tune_rounded, onTap: _openFilter),
        ],
      ),
    );
  }

  Widget _buildActiveFilter(int count) {
    final parts = <String>[
      if (_filter.openBeforeHour != null) 'Mở trước ${Fmt.two(_filter.openBeforeHour!)}:00',
      if (_filter.closeAfterHour != null) _filter.closeAfterHour == 24 ? 'Mở đến 24:00' : 'Đóng sau ${Fmt.two(_filter.closeAfterHour!)}:00',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(children: [
          const Icon(Icons.filter_alt_rounded, size: 16, color: AppColor.primary),
          const SizedBox(width: 6),
          Expanded(child: Text('${parts.join(' · ')}  ·  $count kết quả', style: AppText.label(color: AppColor.primaryDark), overflow: TextOverflow.ellipsis)),
          SzIconButton(Icons.close_rounded, size: 32, color: AppColor.primaryDark, onPressed: () => setState(() => _filter = const FilterModel())),
        ]),
      ),
    );
  }

  List<Widget> _buildSkeletons() => List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SzCard(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              AspectRatio(aspectRatio: 16 / 9, child: SzSkeleton(height: double.infinity, radius: 0)),
              Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 6), child: SzSkeleton(width: 200, height: 18)),
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: SzSkeleton(width: 260, height: 14)),
            ]),
          ),
        ),
      );
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onFilterTap;
  const _PromoBanner({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [AppColor.primaryDark, AppColor.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: AppShadow.primaryGlow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(right: -30, top: -10, child: CustomPaint(size: const Size(150, 150), painter: _ShuttleLinesPainter())),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SzPill.accent('MẸO ĐẶT SÂN', icon: Icons.bolt_rounded),
              const SizedBox(height: 10),
              Text('Tìm sân hợp giờ chơi của bạn', style: AppText.headlineLg(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Lọc theo giờ mở & đóng cửa để chọn được sân phù hợp lịch tập.', style: AppText.body(color: const Color(0xFFCFF5D6))),
              const SizedBox(height: 14),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: onFilterTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Lọc giờ mở cửa', style: AppText.labelLg(color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ShuttleLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width / 2, p);
    for (var i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      canvas.drawLine(c, c + Offset.fromDirection(angle, size.width / 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
