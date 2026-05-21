// lib/ui/highlight/highlight_screen.dart

import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../highlight/api/highlight_api.dart';
import '../highlight/models/hot_court_model.dart';
import '../highlight/widgets/hot_court_card.dart';

class HighlightScreen extends StatefulWidget {
  const HighlightScreen({super.key});

  @override
  State<HighlightScreen> createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<HighlightScreen>
    with AutomaticKeepAliveClientMixin {
  List<HotCourtItem> _hotCourts = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  bool get wantKeepAlive => true; // giữ state khi switch tab

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg  = null;
    });

    try {
      final items = await HighlightApi.getHotCourtItems();
      if (!mounted) return;
      setState(() {
        _hotCourts = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg  = 'Không thể tải dữ liệu. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _goToBooking(CumSanModel court) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScheduleScreen(cumSan: court),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: RefreshIndicator(
        color: AppColor.kCourtGreen,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            if (_isLoading)
              SliverFillRemaining(child: _buildLoading())
            else if (_errorMsg != null)
              SliverFillRemaining(child: _buildError())
            else if (_hotCourts.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else ...[
                  // Top 1 — hero card (bigger)
                  SliverToBoxAdapter(
                    child: _buildHeroSection(),
                  ),

                  // Top 2+ — ranked list
                  SliverToBoxAdapter(
                    child: _buildRankedSection(),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24),
                  ),
                ],
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  SliverAppBar _buildSliverHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 165,
      floating: false,
      pinned: true,
      backgroundColor: AppColor.kDeepGreen,
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadData,
          icon: _isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColor.kAccentYellow, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'SmashZone',
                      style: TextStyle(
                        color: AppColor.kAccentYellow,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const Text(
                  'Nổi Bật',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Những sân được đặt nhiều nhất',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: const Text(
        'Nổi Bật',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }

  // ── Hero section — #1 court ───────────────────────────────────────────────
  Widget _buildHeroSection() {
    if (_hotCourts.isEmpty) return const SizedBox.shrink();
    final top = _hotCourts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColor.kAccentYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sân số 1 tuần này',
                style: TextStyle(
                  color: AppColor.kTextDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColor.kAccentYellow, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _HeroCourtCard(
          item: top,
          onTap: () => _goToBooking(top.cumSan),
        ),
      ],
    );
  }

  // ── Ranked list — #2+ ────────────────────────────────────────────────────
  Widget _buildRankedSection() {
    if (_hotCourts.length <= 1) return const SizedBox.shrink();
    final rest = _hotCourts.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColor.kCourtGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Các sân nổi bật khác',
                style: TextStyle(
                  color: AppColor.kTextDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...rest.map((item) => HotCourtCard(
          item: item,
          onTap: () => _goToBooking(item.cumSan),
        )),
      ],
    );
  }

  // ── States ────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          _SkeletonCard(height: 260, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16)),
          ...List.generate(
            3,
                (_) => _SkeletonCard(
              height: 200,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey[300], size: 56),
          const SizedBox(height: 14),
          Text(_errorMsg!,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kCourtGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis_rounded, color: Colors.grey[300], size: 56),
          const SizedBox(height: 14),
          Text('Chưa có dữ liệu nổi bật',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Hero card — #1 court (larger, more dramatic) ──────────────────────────────
class _HeroCourtCard extends StatelessWidget {
  final HotCourtItem item;
  final VoidCallback onTap;

  const _HeroCourtCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D3B20).withOpacity(0.55),
              blurRadius: 30,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0D3B20),
                        Color(0xFF1A7A3C),
                        Color(0xFF2E9E50),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Court pattern
              Positioned.fill(child: _CourtPatternOverlay()),

              // Shimmer overlay top
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.kAccentYellow.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.kAccentYellow.withOpacity(0.05),
                  ),
                ),
              ),

              // Bottom gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),

              // #1 badge
              Positioned(
                top: 18,
                left: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColor.kAccentYellow,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.kAccentYellow.withOpacity(0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFF1A1A00), size: 14),
                      SizedBox(width: 5),
                      Text('SÂN HOT #1',
                          style: TextStyle(
                            color: Color(0xFF1A1A00),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          )),
                    ],
                  ),
                ),
              ),

              // Booking count top-right
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: Colors.greenAccent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${item.rankData.soLuongDat} lượt đặt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Court info bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.cumSan.tenCumSan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1.15,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // Address
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: Colors.white.withOpacity(0.75),
                                    size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.cumSan.diaChi,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hours chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1),
                            ),
                            child: Text(
                              '${_trim(item.cumSan.gioMoCua)}–${_trim(item.cumSan.gioDongCua)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // CTA row
                      Row(
                        children: [
                          // moTa
                          Expanded(
                            child: Text(
                              item.cumSan.moTa,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Book button
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColor.kAccentYellow,
                                  Color(0xFFFFEE58),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.kAccentYellow
                                      .withOpacity(0.55),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'ĐẶT SÂN NGAY',
                              style: TextStyle(
                                color: AppColor.kDeepGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trim(String t) {
    final p = t.split(':');
    if (p.length >= 2) return '${p[0]}:${p[1]}';
    return t;
  }
}

// ── Skeleton loading card ─────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final double height;
  final EdgeInsets margin;
  const _SkeletonCard({required this.height, required this.margin});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.grey[200]!,
              Color.lerp(Colors.grey[200], Colors.grey[100], _anim.value)!,
              Colors.grey[200]!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CourtPatternOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CourtPatternPainter(),
    );
  }
}

class _CourtPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Đường giữa sân (ngang)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Đường giữa sân (dọc)
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Vòng tròn trung tâm
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.22,
      paint,
    );

    // Đường biên trên/dưới
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.08,
      size.width * 0.88,
      size.height * 0.84,
    );
    canvas.drawRect(rect, borderPaint);

    // Vùng 3 điểm (cung cầu lông style)
    final arcRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width * 0.55,
      height: size.height * 0.9,
    );
    canvas.drawArc(arcRect, -3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}