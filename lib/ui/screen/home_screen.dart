// lib/ui/home/home_screen.dart

import 'package:application/api/FavoriteApi.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/services/distance_service.dart';
import 'package:application/ui/screen/ClaimVoucherScreen.dart';
import 'package:application/ui/screen/chat_screen.dart';
import 'package:application/ui/screen/favorite_list_screen.dart';
import 'package:application/ui/screen/highlight_screen.dart';
import 'package:application/ui/screen/account_screen.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/screen/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/widgets/home_header.dart';
import '../home/widgets/home_search_bar.dart';
import '../home/widgets/promo_banner.dart';
import '../home/widgets/venue_card.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/filter_bottom_sheet.dart';
import '../home/models/filter_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeNavTab _currentTab = HomeNavTab.home;

  String _userName = '';
  late final String _dateLabel = getTodayLabel();

  static const _avartarUrl =
      'https://encrypted-tbn0.gstatic.com/licensed-image?q=tbn:ANd9GcQjVuDVB12oj11fUHVG2fsgMKvglnd7eiANa4oR-6nZCbEZc_lajUm1iFn_Edl_0BwPwiDpfH_QefmCUNmvsPOUu4XlUJlcqg82LWyV3wdisFH-An2HNLLgVZ3sUpTbkyh2KfaPfgm_KCZf&s=19';
  static const _notifCount = 0;

  List<CumSanModel> courtList      = [];
  Map<String, String> courtImage   = {};
  Map<String, String> _distanceMap = {};

  bool _isLoadingCourts    = true;
  bool _isLoadingDistances = false;
  Position? _userPosition;

  Set<String> _favMaCumSanSet = {};
  Map<String, String> _favMaFavMap = {};

  // ── Filter ─────────────────────────────────────────────────────────────────
  FilterModel _filter = const FilterModel();

  List<CumSanModel> get _filteredList {
    if (_filter.isEmpty) return courtList;
    return courtList.where((court) {
      final openHour  = _parseHour(court.gioMoCua);
      final closeHour = _parseHour(court.gioDongCua);
      if (_filter.openBeforeHour != null &&
          openHour > _filter.openBeforeHour!) return false;
      if (_filter.closeAfterHour != null) {
        final threshold =
        _filter.closeAfterHour == 24 ? 23 : _filter.closeAfterHour!;
        if (closeHour < threshold) return false;
      }
      return true;
    }).toList();
  }

  int _parseHour(String t) {
    try { return int.parse(t.split(':')[0]); } catch (_) { return 0; }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadData();
  }

  Future<void> _loadFavorites({String? username}) async {
    final name = username ?? _userName;
    if (name.isEmpty) return;
    try {
      final map = await FavoriteApi.getFavorites(_userName);
      if (!mounted) return;
      setState(() {
        _favMaFavMap    = map;
        _favMaCumSanSet = map.keys.toSet();
      });
    } catch (e) {
      debugPrint('Lỗi load favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String maCumSan) async {
    if (_userName.isEmpty) return;
    final isFav = _favMaCumSanSet.contains(maCumSan);

    if (isFav) {
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
      }
    } else {
      // Optimistic update UI trước
      setState(() => _favMaCumSanSet.add(maCumSan));

      final ok = await FavoriteApi.addFavorite(_userName, maCumSan);
      if (ok && mounted) {
        // Gọi lại để lấy maFav vừa được tạo
        await _loadFavorites();
      } else if (!ok && mounted) {
        // Roll back nếu thất bại
        setState(() => _favMaCumSanSet.remove(maCumSan));
      }
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final username = prefs.getString('username') ?? '';
    setState(() => _userName = username);
    await _loadFavorites(username: username);
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingCourts = true);

    try {
      final results = await Future.wait([
        CumSanApi.getCumSan(1000),
        HinhAnhSanApi.getAllHinhAnhSan(),
        DistanceService.getCurrentPosition(),
      ]);

      if (!mounted) return;

      courtList     = (results[0] as List<CumSanModel>?) ?? [];
      courtImage    = (results[1] as Map<String, String>?) ?? {};
      _userPosition = results[2] as Position?;

      setState(() => _isLoadingCourts = false);

      if (_userPosition != null && courtList.isNotEmpty) {
        await _loadDistances();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCourts = false);
    }
  }

  Future<void> _loadDistances() async {
    if (_userPosition == null || courtList.isEmpty) return;

    setState(() => _isLoadingDistances = true); // FIX: set loading

    final addresses = courtList.map((c) => c.diaChi).toList();
    final distances = await DistanceService.getDistanceBatch(
      originLat: _userPosition!.latitude,
      originLng: _userPosition!.longitude,
      destinationAddresses: addresses,
    );

    if (!mounted) return;

    // FIX: lưu vào _distanceMap state thay vì newMap local
    for (int i = 0; i < courtList.length; i++) {
      if (i < distances.length && distances[i] != null) {
        _distanceMap[courtList[i].maCumSan] = distances[i]!;
      }
    }

    setState(() => _isLoadingDistances = false);
  }

  String getTodayLabel() {
    initializeDateFormatting('vi_VN');
    final now     = DateTime.now();
    final weekday = DateFormat('EEEE', 'vi_VN').format(now);
    final date    = DateFormat('dd/MM/yyyy').format(now);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}, $date';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),

      body: IndexedStack(
        index: _currentTab.index,
        children: [
          // HOME TAB
          RefreshIndicator(
            color: AppColor.kCourtGreen,
            onRefresh: () async => _loadData(), // hoặc gọi lại _loadData()
            child: Column(
              children: [
                _buildGreenHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),

          // CHAT TAB
          const ChatScreen(),

          // EXPLORE TAB
          const ClaimVoucherScreen(),

          // HIGHLIGHT TAB
          const HighlightScreen(),

          // ACCOUNT TAB
          const AccountScreen(),
        ],
      ),

      bottomNavigationBar: HomeBottomNav(
        currentTab: _currentTab,
        onTabChanged: (tab) {
          setState(() {
            _currentTab = tab;
          });
        },
      ),
    );
  }

  Widget _buildGreenHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.kDeepGreen, AppColor.kCourtGreen, Color(0xFF2E9E50)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 0),
            painter: _HeaderCourtLinePainter(),
          ),
          HomeHeader(
            userName: _userName,
            dateLabel: _dateLabel,
            avartarUrl: _avartarUrl,
            notificationCount: _notifCount,
            onNotificationTap: _onNotificationTap,
            onAvatarTap: _onAvatarTap,
          ),
          HomeSearchBar(
            onSearchTap: _onSearchTap,
            onQrTap: _onQrTap,
            onFavoriteTap: _onFavoriteTap,
            hasFavorite:   _favMaCumSanSet.isNotEmpty,
          ),
          Container(
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final filtered = _filteredList;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 4),
        PromoBanner(onFilterTap: _onFilterTap),

        // Badge filter đang active
        if (!_filter.isEmpty) _buildActiveFilterBadge(),

        const SizedBox(height: 16),

        if (_isLoadingCourts)
          _buildLoadingList()
        else if (filtered.isEmpty)
          _buildEmptyState()
        else
          ..._buildVenueList(filtered),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Thanh nhỏ hiển thị filter đang dùng + nút xoá nhanh
  Widget _buildActiveFilterBadge() {
    final parts = <String>[];
    if (_filter.openBeforeHour != null) {
      parts.add('Mở trước ${_filter.openBeforeHour}:00');
    }
    if (_filter.closeAfterHour != null) {
      final label = _filter.closeAfterHour == 24
          ? '23:59'
          : '${_filter.closeAfterHour}:00';
      parts.add('Đóng sau $label');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              color: AppColor.kCourtGreen, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              parts.join(' • '),
              style: const TextStyle(
                color: AppColor.kCourtGreen,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Số kết quả
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColor.kMintField,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!, width: 1),
            ),
            child: Text(
              '${_filteredList.length} sân',
              style: const TextStyle(
                  color: AppColor.kCourtGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          // Xoá filter nhanh
          GestureDetector(
            onTap: () => setState(() => _filter = const FilterModel()),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close_rounded,
                  color: Colors.red[400], size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        3,
            (_) => Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: AppColor.kCourtGreen, strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = !_filter.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(
            hasFilter
                ? Icons.filter_alt_off_rounded
                : Icons.sports_tennis_rounded,
            color: Colors.grey[300],
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Không có sân nào khớp với bộ lọc hiện tại'
                : 'Không tìm thấy sân nào',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _filter = const FilterModel()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.kMintField,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: const Text('Xoá bộ lọc',
                    style: TextStyle(
                        color: AppColor.kCourtGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FIX: nhận list đã filter thay vì dùng courtList trực tiếp
  List<Widget> _buildVenueList(List<CumSanModel> list) {
    final result = <Widget>[];

    for (final court in list) {
      final distance = _distanceMap[court.maCumSan];

      result.add(
        VenueCard(
          court: court,
          courtImage: courtImage[court.maCumSan] ?? '',
          // FIX: truyền distance và loading state
          distance: distance,
          isLoadingDistance: _isLoadingDistances && distance == null,
          onBookTap: () => _goToBooking(court),
          isFav: _favMaCumSanSet.contains(court.maCumSan),
          onFavoriteTap: () => _toggleFavorite(court.maCumSan),
          onDirectionTap: () => _onDirectionTap(court),
          onCardTap: () => _goToBooking(court),
        ),
      );
      result.add(const SizedBox(height: 14));
    }

    return result;
  }

  // ── Callbacks ──────────────────────────────────────────────────────────────

  void _onNotificationTap() {}
  void _onAvatarTap() {}
  void _onQrTap() {}
  void _onFavoriteTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoriteListScreen(
          courtList:      courtList,
          courtImage:     courtImage,
          favMaCumSanSet: _favMaCumSanSet,
          onFavoriteTap:  _toggleFavorite,
          onBookTap:      _goToBooking,
        ),
      ),
    );
  }
  void _onDirectionTap(CumSanModel court) async {
    final encodedAddress = Uri.encodeComponent(court.diaChi);

    final Uri geoUrl = Uri.parse('geo:0,0?q=$encodedAddress');
    final Uri webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _onSearchTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          courtList:   courtList,
          courtImage:  courtImage,
        ),
      ),
    );
  }

  // FIX: implement _onFilterTap
  void _onFilterTap() {
    FilterBottomSheet.show(
      context: context,
      currentFilter: _filter,
      onApply: (newFilter) => setState(() => _filter = newFilter),
    );
  }

  void _goToBooking(CumSanModel court) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScheduleScreen(cumSan: court),
      ),
    );
  }
}

class _HeaderCourtLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
          Offset(0, 20.0 + i * 28), Offset(size.width, 20.0 + i * 28), p);
    }
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, 120), p);
  }

  @override
  bool shouldRepaint(_) => false;
}