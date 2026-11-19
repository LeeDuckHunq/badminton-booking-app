// Đánh giá cụm sân: viên điểm sao, sheet xem đánh giá, sheet viết đánh giá.
import 'package:application/api/danh_gia_api.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

/// "★ 4.8 (128)" – dùng trên ảnh card cụm sân. Ẩn khi chưa có đánh giá (trừ khi [showEmpty]).
class RatingPill extends StatelessWidget {
  final double? score;
  final int count;
  final VoidCallback? onTap;
  final bool showEmpty;

  const RatingPill({super.key, required this.score, required this.count, this.onTap, this.showEmpty = false});

  @override
  Widget build(BuildContext context) {
    if (score == null && !showEmpty) return const SizedBox.shrink();
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(999), boxShadow: AppShadow.card),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColor.accentDeep),
        const SizedBox(width: 3),
        if (score == null)
          Text('Chưa có đánh giá', style: AppText.label())
        else ...[
          Text(score!.toStringAsFixed(1).replaceAll('.', ','), style: AppText.label().copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 3),
          Text('($count)', style: AppText.label(color: AppColor.textMuted)),
        ],
        if (onTap != null) ...[const SizedBox(width: 2), const Icon(Icons.chevron_right_rounded, size: 16, color: AppColor.textMuted)],
      ]),
    );
    return onTap == null ? pill : GestureDetector(onTap: onTap, child: pill);
  }
}

/// "★ 4,8 (12)" dạng chữ, dùng trong dòng thông tin. Ẩn khi chưa có đánh giá.
class RatingInline extends StatelessWidget {
  final double? score;
  final int count;
  final double size;
  const RatingInline({super.key, required this.score, required this.count, this.size = 15});

  @override
  Widget build(BuildContext context) {
    if (score == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, size: size + 1, color: AppColor.accentDeep),
      const SizedBox(width: 2),
      Text(score!.toStringAsFixed(1).replaceAll('.', ','), style: AppText.label().copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 3),
      Text('($count)', style: AppText.bodySm()),
    ]);
  }
}

class StarRow extends StatelessWidget {
  final double value;
  final double size;
  const StarRow(this.value, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          value >= i ? Icons.star_rounded : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: size,
          color: AppColor.accentDeep,
        ),
    ]);
  }
}

// ═══════════════════════════════ XEM ĐÁNH GIÁ ═══════════════════════════════

Future<void> showVenueReviewsSheet(BuildContext context, CumSanModel venue) {
  return showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _VenueReviewsSheet(venue: venue));
}

class _VenueReviewsSheet extends StatefulWidget {
  final CumSanModel venue;
  const _VenueReviewsSheet({required this.venue});

  @override
  State<_VenueReviewsSheet> createState() => _VenueReviewsSheetState();
}

class _VenueReviewsSheetState extends State<_VenueReviewsSheet> {
  VenueReviews? _data;
  bool _failed = false;
  int? _starFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final data = await DanhGiaApi.venueReviews(widget.venue.maCumSan);
    if (!mounted) return;
    setState(() {
      _data = data;
      _failed = data == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final list = d == null ? <VenueReview>[] : d.reviews.where((r) => _starFilter == null || r.soSao == _starFilter).toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SzSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Đánh giá cụm sân', style: AppText.headlineMd()),
                Text(widget.venue.tenCumSan, style: AppText.body(color: AppColor.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            SzIconButton(Icons.close_rounded, color: AppColor.textMuted, onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Flexible(
          child: _failed
              ? SzErrorState(message: 'Không tải được đánh giá.', onRetry: _load)
              : d == null
                  ? const Padding(padding: EdgeInsets.all(40), child: SzLoading())
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
                      children: [
                        _Summary(data: d),
                        const SizedBox(height: 12),
                        if (d.soDanhGia > 0)
                          SizedBox(
                            height: 40,
                            child: ListView(scrollDirection: Axis.horizontal, children: [
                              SzChip('Tất cả', count: d.soDanhGia, selected: _starFilter == null, onTap: () => setState(() => _starFilter = null)),
                              for (var s = 5; s >= 1; s--) ...[
                                const SizedBox(width: 8),
                                SzChip('$s sao', icon: Icons.star_rounded, count: d.phanBo[s] ?? 0, selected: _starFilter == s, onTap: () => setState(() => _starFilter = s)),
                              ],
                            ]),
                          ),
                        const SizedBox(height: 12),
                        if (d.soDanhGia == 0)
                          const SzEmptyState(icon: Icons.reviews_outlined, title: 'Chưa có đánh giá nào', message: 'Hãy là người đầu tiên đánh giá sau khi chơi tại đây.')
                        else if (list.isEmpty)
                          Padding(padding: const EdgeInsets.all(24), child: Text('Không có đánh giá $_starFilter sao.', textAlign: TextAlign.center, style: AppText.body(color: AppColor.textMuted)))
                        else
                          for (final r in list) _ReviewTile(review: r),
                      ],
                    ),
        ),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  final VenueReviews data;
  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.phanBo.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(children: [
        SizedBox(
          width: 104,
          child: Column(children: [
            Text(data.diemTrungBinh == null ? '–' : data.diemTrungBinh!.toStringAsFixed(1).replaceAll('.', ','), style: AppText.stat(size: 40, color: AppColor.primaryDark)),
            StarRow(data.diemTrungBinh ?? 0, size: 16),
            const SizedBox(height: 4),
            Text('${data.soDanhGia} đánh giá', style: AppText.bodySm(color: AppColor.text)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            for (var s = 5; s >= 1; s--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  SizedBox(width: 14, child: Text('$s', style: AppText.label())),
                  const Icon(Icons.star_rounded, size: 13, color: AppColor.accentDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : (data.phanBo[s] ?? 0) / max,
                        minHeight: 7,
                        backgroundColor: Colors.white,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 28, child: Text('${data.phanBo[s] ?? 0}', textAlign: TextAlign.right, style: AppText.bodySm())),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final VenueReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SzCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SzAvatar.soft(review.tenNguoiDanhGia, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(review.tenNguoiDanhGia, style: AppText.labelLg()),
                Row(children: [
                  StarRow(review.soSao.toDouble(), size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      [if (review.ngayTao != null) Fmt.date(review.ngayTao!), if (review.tenSan != null) review.tenSan!, if (review.daSua) 'đã sửa'].join(' · '),
                      style: AppText.bodySm(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
          if (review.noiDung != null && review.noiDung!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.noiDung!, style: AppText.body()),
          ],
          if (review.phanHoi != null && review.phanHoi!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md), border: const Border(left: BorderSide(color: AppColor.primary, width: 3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.storefront_outlined, size: 15, color: AppColor.primary),
                  const SizedBox(width: 6),
                  Text('Phản hồi từ chủ sân', style: AppText.label(color: AppColor.primaryDark)),
                ]),
                const SizedBox(height: 4),
                Text(review.phanHoi!, style: AppText.body()),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ═══════════════════════════════ VIẾT ĐÁNH GIÁ ═══════════════════════════════

/// Trả về true nếu đã gửi thành công.
Future<bool> showWriteReviewSheet(BuildContext context, {required String maPhieuDat, required String venueName, String? courtName, MyReview? existing}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WriteReviewSheet(maPhieuDat: maPhieuDat, venueName: venueName, courtName: courtName, existing: existing),
  );
  return result ?? false;
}

class _WriteReviewSheet extends StatefulWidget {
  final String maPhieuDat;
  final String venueName;
  final String? courtName;
  final MyReview? existing;

  const _WriteReviewSheet({required this.maPhieuDat, required this.venueName, this.courtName, this.existing});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  static const _labels = ['', 'Rất tệ', 'Chưa tốt', 'Bình thường', 'Tốt', 'Tuyệt vời'];
  static const _tags = ['Sân sạch sẽ', 'Thảm tốt', 'Đèn sáng', 'Thoáng mát', 'Chủ sân thân thiện', 'Giá hợp lý', 'Dễ tìm, có chỗ đậu xe'];

  late int _stars = widget.existing?.soSao ?? 0;
  late final _text = TextEditingController(text: widget.existing?.noiDung ?? '');
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final current = _text.text.trim();
    if (current.contains(tag)) {
      _text.text = current.replaceAll(RegExp('(, )?${RegExp.escape(tag)}'), '').replaceFirst(RegExp(r'^, '), '');
    } else {
      _text.text = current.isEmpty ? tag : '$current, $tag';
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      showSzSnack(context, 'Chọn số sao trước nhé', type: SzToast.warning);
      return;
    }
    setState(() => _sending = true);
    final error = await DanhGiaApi.submit(maPhieuDat: widget.maPhieuDat, soSao: _stars, noiDung: _text.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      showSzSnack(context, error, type: SzToast.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SzSheetHandle(),
            SzSheetHeader(
              icon: Icons.rate_review_outlined,
              title: widget.existing == null ? 'Đánh giá lần chơi' : 'Sửa đánh giá',
              subtitle: [widget.venueName, if (widget.courtName != null) widget.courtName!].join(' · '),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 44,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: i <= _stars ? AppColor.accentDeep : AppColor.borderStrong),
                  tooltip: _labels[i],
                ),
            ]),
            Text(_stars == 0 ? 'Chạm để chọn số sao' : _labels[_stars], textAlign: TextAlign.center, style: AppText.headlineSm(color: _stars == 0 ? AppColor.textMuted : AppColor.primaryDark)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final tag in _tags) SzChip(tag, selected: _text.text.contains(tag), onTap: () => _toggleTag(tag)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              maxLines: 4,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              style: AppText.body(),
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn về sân, ánh sáng, dịch vụ…',
                hintStyle: AppText.body(color: AppColor.textSubtle),
                filled: true,
                fillColor: AppColor.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            SzButton(widget.existing == null ? 'Gửi đánh giá' : 'Cập nhật đánh giá', expand: true, loading: _sending, trailingIcon: Icons.send_rounded, onPressed: _submit),
            const SizedBox(height: 8),
            Text('Đánh giá hiển thị công khai với tên gọi của bạn (không hiện tên đăng nhập).', textAlign: TextAlign.center, style: AppText.bodySm()),
          ]),
        ),
      ),
    );
  }
}
