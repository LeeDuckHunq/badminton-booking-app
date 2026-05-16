// lib/ui/home/home_screen.dart

import 'package:application/api/cum_san_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/services/distance_service.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/models/home_model.dart';
import '../home/widgets/home_header.dart';
import '../home/widgets/home_search_bar.dart';
import '../home/widgets/promo_banner.dart';
import '../home/widgets/venue_card.dart';
import '../home/widgets/home_bottom_nav.dart';

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
  static const _notifCount = 3;

  List<CumSanModel> courtList    = [];
  Map<String, String> courtImage = {};
  Map<String, String> _distanceMap = {};

  bool _isLoadingCourts    = true;
  bool _isLoadingDistances = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _userName = prefs.getString('username') ?? '');
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingCourts = true);

    try {
      final results = await Future.wait([
        CumSanApi.getCumSan(10),
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

    setState(() => _isLoadingDistances = true);

    // Gửi 1 request batch cho tất cả sân
    final addresses = courtList.map((c) => c.diaChi).toList();
    final distances = await DistanceService.getDistanceBatch(
      originLat: _userPosition!.latitude,
      originLng: _userPosition!.longitude,
      destinationAddresses: addresses,
    );

    if (!mounted) return;

    final newMap = <String, String>{};
    for (int i = 0; i < courtList.length; i++) {
      if (i < distances.length && distances[i] != null) {
        newMap[courtList[i].maCumSan] = distances[i]!;
      }
    }

    setState(() {
      _distanceMap        = newMap;
      _isLoadingDistances = false;
    });
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildGreenHeader(),
          Expanded(child: _buildBody()),
          HomeBottomNav(
            currentTab: _currentTab,
            onTabChanged: (tab) => setState(() => _currentTab = tab),
          ),
        ],
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 4),
        PromoBanner(onFilterTap: _onFilterTap),
        const SizedBox(height: 16),

        // Cảnh báo nếu không lấy được GPS
        if (!_isLoadingCourts && _userPosition == null)
          _buildLocationWarning(),

        if (_isLoadingCourts)
          _buildLoadingList()
        else if (courtList.isEmpty)
          _buildEmptyState()
        else
          ..._buildVenueList(),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationWarning() {
    return GestureDetector(
      onTap: () => Geolocator.openLocationSettings(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5)),
        ),
        child: Row(
          children: const [
            Icon(Icons.location_off_rounded, color: Color(0xFFFF8F00), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bật định vị để xem khoảng cách thực tế đến sân',
                style: TextStyle(
                  color: Color(0xFF6D4C00),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFF8F00), size: 14),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.sports_tennis_rounded, color: Colors.grey[300], size: 56),
          const SizedBox(height: 12),
          Text('Không tìm thấy sân nào',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildVenueList() {
    final result = <Widget>[];

    for (final court in courtList) {
      final distance = _distanceMap[court.maCumSan];

      result.add(
        VenueCard(
          court: court,
          courtImage: courtImage[court.maCumSan] ?? '',
          // null = đang tính, String = đã có
          distance: distance,
          isLoadingDistance: _isLoadingDistances && distance == null,
          onBookTap: () => _onBookTap(court),
          onFavoriteTap: _onFavoriteTap,
          onDirectionTap: () => _onDirectionTap(court),
          onCardTap: () => _onVenueCardTap(court),
        ),
      );
      result.add(const SizedBox(height: 14));
    }

    return result;
  }

  void _onNotificationTap() {}
  void _onAvatarTap() {}
  void _onSearchTap() {}
  void _onQrTap() {}
  void _onFavoriteTap() {}
  void _onFilterTap() {}
  void _onBookTap(CumSanModel court) => _goToBooking(court);
  void _onDirectionTap(CumSanModel court) {}
  void _onVenueCardTap(CumSanModel court) => _goToBooking(court);

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