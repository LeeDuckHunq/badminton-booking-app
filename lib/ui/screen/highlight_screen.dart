// lib/ui/screen/highlight_screen.dart
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/review/review_widgets.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

import '../highlight/api/highlight_api.dart';
import '../highlight/models/hot_court_model.dart';

/// M14 – Bảng xếp hạng cụm sân được đặt nhiều nhất (tab Nổi bật).
class HighlightScreen extends StatefulWidget {
  /// Mở như màn con (có nút quay lại) thay vì tab.
  final bool standalone;

  const HighlightScreen({super.key, this.standalone = false});

  @override
  State<HighlightScreen> createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<HighlightScreen> with AutomaticKeepAliveClientMixin {
  List<HotCourtItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await HighlightApi.getHotCourtItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải bảng xếp hạng. Vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  void _book(CumSanModel court) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScheduleScreen(cumSan: court)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(children: [
        if (widget.standalone) const SzTopBar(title: 'Sân nổi bật', subtitle: 'Bảng xếp hạng cụm sân') else const SzBrandHeader(subtitle: 'Nổi bật'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(children: [
                  const Icon(Icons.military_tech_rounded, color: AppColor.accentDeep, size: 26),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Bảng xếp hạng sân', style: AppText.headlineLg(color: AppColor.text))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text('Top cụm sân được đặt nhiều nhất', style: AppText.body(color: AppColor.textMuted))),
                  const SzPill('TOÀN THỜI GIAN', icon: Icons.circle, bold: true),
                ]),
                const SizedBox(height: 16),
                if (_loading) ...[
                  const SzSkeleton(height: 320, radius: AppRadius.lg),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SzSkeleton(height: 92, radius: AppRadius.lg)),
                ] else if (_error != null)
                  SzErrorState(message: _error!, onRetry: _load)
                else if (_items.isEmpty)
                  const SzEmptyState(icon: Icons.emoji_events_outlined, title: 'Chưa có dữ liệu nổi bật', message: 'Bảng xếp hạng sẽ xuất hiện khi có lượt đặt sân.')
                else ...[
                  _TopCard(item: _items.first, onBook: () => _book(_items.first.cumSan)),
                  if (_items.length > 1) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      const Icon(Icons.bar_chart_rounded, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text('Top 2 – ${_items.length} thịnh hành', style: AppText.headlineSm()),
                    ]),
                    const SizedBox(height: 10),
                    for (final item in _items.skip(1)) _RankRow(item: item, onBook: () => _book(item.cumSan)),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.verified_outlined, color: AppColor.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Dữ liệu minh bạch toàn hệ thống', style: AppText.labelLg(color: AppColor.primaryDark)),
                          const SizedBox(height: 2),
                          Text('Thứ hạng được tính tự động theo tổng số lượt đặt sân trên SmashZone.', style: AppText.bodySm(color: AppColor.text)),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _TopCard extends StatelessWidget {
  final HotCourtItem item;
  final VoidCallback onBook;
  const _TopCard({required this.item, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final c = item.cumSan;
    return SzCard(
      padding: EdgeInsets.zero,
      onTap: onBook,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(fit: StackFit.expand, children: [
            SzNetworkImage(item.imageUrl),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xB3001A08)], stops: [0.45, 1]))),
            const Positioned(top: 12, left: 12, child: SzPill.accent('#1 TOÀN HỆ THỐNG', icon: Icons.emoji_events_rounded)),
            Positioned(
              left: 14,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('KỶ LỤC ĐẶT SÂN', style: AppText.labelSm(color: const Color(0xFFCFF5D6))),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(Fmt.number(item.rankData.soLuongDat), style: AppText.stat(size: 32, color: Colors.white)),
                  const SizedBox(width: 6),
                  Text('lượt', style: AppText.label(color: Colors.white)),
                ]),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.tenCumSan, style: AppText.headlineMd(color: AppColor.forest), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (c.diemDanhGia != null) ...[RatingInline(score: c.diemDanhGia, count: c.soDanhGia), const SizedBox(width: 8)],
              if (c.soSan > 0) SzPill('${c.soSan} sân'),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColor.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text(c.diaChi, style: AppText.body(color: AppColor.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 15, color: AppColor.textMuted),
              const SizedBox(width: 4),
              Text(Fmt.hours(c.gioMoCua, c.gioDongCua), style: AppText.body(color: AppColor.textMuted)),
              if (c.giaTu != null) ...[
                const Spacer(),
                Text('Từ ${Fmt.money(c.giaTu!)}/h', style: AppText.labelLg(color: AppColor.primaryDark)),
              ],
            ]),
            const SizedBox(height: 14),
            SzButton('Đặt sân ngay', uppercase: true, expand: true, kind: SzButtonKind.dark, trailingIcon: Icons.arrow_forward_rounded, onPressed: onBook),
          ]),
        ),
      ]),
    );
  }
}

class _RankRow extends StatelessWidget {
  final HotCourtItem item;
  final VoidCallback onBook;
  const _RankRow({required this.item, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final c = item.cumSan;
    final (badgeBg, badgeFg) = switch (item.rank) {
      2 => (const Color(0xFFE2E8F0), AppColor.text),
      3 => (const Color(0xFFF5D0A9), const Color(0xFF7C2D12)),
      _ => (const Color(0xFFD1F8D5), AppColor.primaryDark),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SzCard(
        padding: const EdgeInsets.all(10),
        onTap: onBook,
        child: Row(children: [
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SzNetworkImage(item.imageUrl, width: 76, height: 72)),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Text('#${item.rank}', style: AppText.labelSm(color: badgeFg).copyWith(fontSize: 11)),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.tenCumSan, style: AppText.headlineSm(), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColor.textMuted),
                const SizedBox(width: 3),
                Expanded(child: Text(c.diaChi, style: AppText.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('${Fmt.number(item.rankData.soLuongDat)} lượt đặt', style: AppText.label(color: AppColor.primary)),
                if (c.diemDanhGia != null) ...[const SizedBox(width: 8), RatingInline(score: c.diemDanhGia, count: c.soDanhGia, size: 13)],
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          SzButton.small('Đặt sân', kind: SzButtonKind.soft, onPressed: onBook),
        ]),
      ),
    );
  }
}
