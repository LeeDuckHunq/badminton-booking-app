// lib/ui/search/search_screen.dart

import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  /// Truyền toàn bộ danh sách sân đã load từ HomeScreen
  final List<CumSanModel> courtList;
  final Map<String, String> courtImage;

  const SearchScreen({
    super.key,
    required this.courtList,
    required this.courtImage,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller  = TextEditingController();
  final _focusNode   = FocusNode();

  String _query = '';
  _FilterType _filterType = _FilterType.all;

  List<CumSanModel> get _filtered {
    if (_query.trim().isEmpty) return widget.courtList;

    final q = _query.toLowerCase().trim();
    return widget.courtList.where((c) {
      switch (_filterType) {
        case _FilterType.all:
          return c.tenCumSan.toLowerCase().contains(q) ||
              c.diaChi.toLowerCase().contains(q);
        case _FilterType.name:
          return c.tenCumSan.toLowerCase().contains(q);
        case _FilterType.address:
          return c.diaChi.toLowerCase().contains(q);
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Auto focus khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  // ── Header: back + search field ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.kLineWhite, size: 20),
                onPressed: () => Navigator.pop(context),
              ),

              // Search field
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                        color: AppColor.kLineWhite, fontSize: 15),
                    cursorColor: AppColor.kAccentYellow,
                    decoration: InputDecoration(
                      hintText: 'Tên sân hoặc địa chỉ...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14.5),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColor.kAccentYellow, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 18),
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter chips: Tất cả / Tên sân / Địa chỉ ─────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: AppColor.kLineWhite,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            _query.isEmpty
                ? '${widget.courtList.length} sân'
                : '${_filtered.length} kết quả',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.5,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          ..._FilterType.values.map((f) {
            final selected = _filterType == f;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filterType = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColor.kCourtGreen
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColor.kCourtGreen
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: selected
                          ? AppColor.kLineWhite
                          : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Results list ──────────────────────────────────────────────────────────
  Widget _buildResults() {
    final results = _filtered;

    if (results.isEmpty) return _buildEmpty();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final court = results[i];
        return _SearchResultCard(
          court: court,
          courtImage: widget.courtImage[court.maCumSan] ?? '',
          query: _query,
          onTap: () => _goToBooking(court),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.grey[300], size: 56),
          const SizedBox(height: 12),
          Text(
            _query.isEmpty
                ? 'Nhập tên sân hoặc địa chỉ để tìm kiếm'
                : 'Không tìm thấy sân nào\nkhớp với "$_query"',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Enum filter type ──────────────────────────────────────────────────────────
enum _FilterType {
  all('Tất cả'),
  name('Tên sân'),
  address('Địa chỉ');

  final String label;
  const _FilterType(this.label);
}

// ── Search result card ────────────────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final CumSanModel court;
  final String courtImage;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.court,
    required this.courtImage,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.kLineWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ảnh sân
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: courtImage.isNotEmpty
                    ? Image.network(courtImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sân (highlight từ khóa)
                    _HighlightText(
                      text: court.tenCumSan,
                      query: query,
                      baseStyle: const TextStyle(
                        color: AppColor.kTextDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Địa chỉ (highlight từ khóa)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: _HighlightText(
                            text: court.diaChi,
                            query: query,
                            baseStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Giờ + khoảng cách
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(
                          '${court.gioMoCua} - ${court.gioDongCua}',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow + book button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColor.kAccentYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ĐẶT\nLỊCH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.kDeepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A6B3C),
    child: const Center(
      child: Icon(Icons.sports_tennis_rounded,
          color: Colors.white30, size: 32),
    ),
  );
}

// ── Highlight matching text ───────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final int maxLines;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: baseStyle.copyWith(
          color: AppColor.kCourtGreen,
          fontWeight: FontWeight.w900,
          backgroundColor: AppColor.kMintField,
        ),
      ));
      start = idx + q.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}