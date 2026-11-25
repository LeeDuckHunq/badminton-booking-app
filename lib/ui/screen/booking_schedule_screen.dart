// lib/ui/screen/booking_schedule_screen.dart
import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/model/create_phieu_dat_model.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/ui/invoice/models/invoice_model.dart';
import 'package:application/ui/screen/invoice_screen.dart';
import 'package:application/ui/review/review_widgets.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../booking/models/booking_state.dart';

/// M7 – Lịch đặt sân (ma trận ô 30 phút).
class BookingScheduleScreen extends StatefulWidget {
  final CumSanModel cumSan;

  const BookingScheduleScreen({super.key, required this.cumSan});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  static const double _nameColWidth = 104;
  static const double _cellWidth = 64;
  static const double _cellHeight = 56;
  static const double _cellGap = 6;

  List<SanModel> _sanList = [];
  List<PhieuDatSanModel> _phieuList = [];
  bool _isLoading = true;
  bool _submitting = false;
  String? _errorMsg;

  late DateTime _selectedDate = _today();
  String? _selectedMaSan;
  final Set<DateTime> _selectedStarts = {};
  Map<String, List<TimeSlot>> _slotMap = {};
  BookingSelection? _selection;

  final _gridScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    super.dispose();
  }

  // ── Dữ liệu ───────────────────────────────────────────────────────────────

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  DateTime _at(DateTime date, TimeOfDay t) => DateTime(date.year, date.month, date.day, t.hour, t.minute);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final results = await Future.wait([
        SanApi.getSanTheoCumSan(widget.cumSan.maCumSan),
        PhieuDatSanApi.getPhieuDatTheoNgay(_selectedDate),
      ]);
      _sanList = results[0] as List<SanModel>;
      _phieuList = results[1] as List<PhieuDatSanModel>;
      _buildSlotMap();
    } catch (_) {
      _errorMsg = 'Không thể tải lịch sân. Vui lòng thử lại.';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _scrollToNow();
  }

  Future<void> _reloadBookings() async {
    setState(() => _isLoading = true);
    try {
      _phieuList = await PhieuDatSanApi.getPhieuDatTheoNgay(_selectedDate);
      _errorMsg = null;
      _clearSelection();
      _buildSlotMap();
    } catch (_) {
      _errorMsg = 'Không thể tải lịch đặt.';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _scrollToNow();
  }

  void _buildSlotMap() {
    final open = _at(_selectedDate, _parseTime(widget.cumSan.gioMoCua));
    var close = _at(_selectedDate, _parseTime(widget.cumSan.gioDongCua));
    if (!close.isAfter(open)) close = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59);

    final booked = <String, List<(DateTime, DateTime)>>{};
    for (final p in _phieuList) {
      if (p.trangThai == 'DA_XAC_NHAN' || p.trangThai == 'CHO_XAC_NHAN') {
        booked.putIfAbsent(p.maSan, () => []).add((p.batDau, p.ketThuc));
      }
    }

    final now = DateTime.now();
    final map = <String, List<TimeSlot>>{};
    for (final san in _sanList) {
      final slots = <TimeSlot>[];
      var cur = open;
      while (cur.isBefore(close)) {
        final end = cur.add(const Duration(minutes: 30));
        final isBooked = (booked[san.maSan] ?? []).any((r) => r.$1.isBefore(end) && r.$2.isAfter(cur));
        final isPast = cur.isBefore(now);
        slots.add(TimeSlot(maSan: san.maSan, start: cur, end: end, status: isPast ? SlotStatus.locked : (isBooked ? SlotStatus.booked : SlotStatus.available)));
        cur = end;
      }
      map[san.maSan] = slots;
    }
    _slotMap = map;
  }

  /// Hôm nay: cuộn lưới tới khung giờ hiện tại.
  void _scrollToNow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gridScroll.hasClients || _sanList.isEmpty) return;
      final slots = _slotMap[_sanList.first.maSan] ?? [];
      final firstOpen = slots.indexWhere((s) => s.status != SlotStatus.locked);
      final index = (firstOpen < 0 ? 0 : firstOpen - 1).clamp(0, slots.length);
      final target = (index * (_cellWidth + _cellGap)).clamp(0.0, _gridScroll.position.maxScrollExtent);
      _gridScroll.jumpTo(target.toDouble());
    });
  }

  // ── Chọn ô ────────────────────────────────────────────────────────────────

  void _onSlotTap(TimeSlot slot) {
    if (!slot.isSelectable) return;
    setState(() {
      if (_selectedMaSan != null && _selectedMaSan != slot.maSan) _clearSelection();
      _selectedMaSan = slot.maSan;
      if (_selectedStarts.contains(slot.start)) {
        final sorted = _selectedStarts.toList()..sort();
        // Bỏ chọn ô ở giữa thì giữ phần liền mạch phía trước.
        if (slot.start != sorted.first && slot.start != sorted.last) {
          _selectedStarts.removeWhere((s) => !s.isBefore(slot.start));
        } else {
          _selectedStarts.remove(slot.start);
        }
        if (_selectedStarts.isEmpty) _selectedMaSan = null;
      } else {
        if (_selectedStarts.isNotEmpty && !_isAdjacent(slot)) _selectedStarts.clear();
        _selectedStarts.add(slot.start);
      }
      _updateSelection();
    });
  }

  bool _isAdjacent(TimeSlot slot) {
    final sorted = _selectedStarts.toList()..sort();
    return slot.start.add(const Duration(minutes: 30)) == sorted.first || slot.start.subtract(const Duration(minutes: 30)) == sorted.last;
  }

  void _updateSelection() {
    if (_selectedStarts.isEmpty || _selectedMaSan == null) {
      _selection = null;
      return;
    }
    final san = _sanList.firstWhere((s) => s.maSan == _selectedMaSan);
    final sorted = _selectedStarts.toList()..sort();
    _selection = BookingSelection(san: san, batDau: sorted.first, ketThuc: sorted.last.add(const Duration(minutes: 30)));
  }

  void _clearSelection() {
    _selectedMaSan = null;
    _selectedStarts.clear();
    _selection = null;
  }

  // ── Đặt sân ───────────────────────────────────────────────────────────────

  void _openConfirm() {
    final sel = _selection;
    if (sel == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(cumSan: widget.cumSan, selection: sel, onConfirm: () => _submit(sel)),
    );
  }

  Future<void> _submit(BookingSelection sel) async {
    Navigator.pop(context);
    setState(() => _submitting = true);
    final result = await PhieuDatSanApi.createPhieuDat(CreatePhieuDatModel(maNguoiDung: '', maSan: sel.san.maSan, batDau: sel.batDau, ketThuc: sel.ketThuc));
    if (!mounted) return;
    setState(() => _submitting = false);

    final maPhieuDat = result.maPhieuDat;
    if (maPhieuDat == null) {
      showSzSnack(context, result.message ?? 'Đặt sân thất bại. Vui lòng thử lại!', type: SzToast.error);
      _reloadBookings();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceScreen(
          maPhieuDat: maPhieuDat,
          booking: InvoiceBookingInfo(
            maPhieuDat: maPhieuDat,
            tenCumSan: widget.cumSan.tenCumSan,
            tenSan: sel.san.tenSan,
            diaChi: widget.cumSan.diaChi,
            batDau: sel.batDau,
            ketThuc: sel.ketThuc,
            tongTien: sel.tongTien,
            giaGio: sel.san.hasTimePricing ? null : sel.san.gia,
          ),
        ),
      ),
    );
    if (mounted) _reloadBookings();
  }

  Future<void> _openMap() async {
    final q = Uri.encodeComponent(widget.cumSan.diaChi);
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'), mode: LaunchMode.externalApplication);
  }

  // ── Giao diện ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SzTopBar(title: 'Đặt lịch sân'),
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildVenueHeader(),
              _buildDateStrip(),
              _buildLegend(),
              if (_isLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: SzLoading(message: 'Đang tải lịch sân…'))
              else if (_errorMsg != null)
                SzErrorState(message: _errorMsg!, onRetry: _loadData)
              else if (_sanList.isEmpty)
                const SzEmptyState(icon: Icons.event_busy_rounded, title: 'Chưa có sân hoạt động', message: 'Cụm sân này hiện chưa mở sân nào để đặt.')
              else
                _buildGrid(),
            ],
          ),
        ),
        if (_submitting)
          Container(color: const Color(0x590D2E18), alignment: Alignment.center, child: const SzCard(child: SzLoading(message: 'Đang giữ chỗ cho bạn…'))),
      ]),
      bottomNavigationBar: _buildSummaryBar(),
    );
  }

  Widget _buildVenueHeader() {
    final c = widget.cumSan;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SzPill('${_sanList.isEmpty ? c.soSan : _sanList.length} sân đang mở', icon: Icons.stadium_outlined),
              const SizedBox(width: 8),
              RatingPill(score: c.diemDanhGia, count: c.soDanhGia, showEmpty: true, onTap: () => showVenueReviewsSheet(context, c)),
            ]),
            const SizedBox(height: 8),
            Text(c.tenCumSan, style: AppText.headlineLg(color: AppColor.primary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 15, color: AppColor.textMuted),
              const SizedBox(width: 4),
              Text(Fmt.hours(c.gioMoCua, c.gioDongCua), style: AppText.body(color: AppColor.textMuted)),
              const SizedBox(width: 10),
              const Icon(Icons.location_on_outlined, size: 15, color: AppColor.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text(c.diaChi, style: AppText.body(color: AppColor.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        SzIconButton(Icons.map_outlined, size: 48, background: AppColor.mint, color: AppColor.primary, tooltip: 'Xem bản đồ', onPressed: _openMap),
      ]),
    );
  }

  Widget _buildDateStrip() {
    final today = _today();
    final days = List.generate(14, (i) => today.add(Duration(days: i)));
    return Container(
      color: AppColor.canvas,
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColor.text),
            const SizedBox(width: 6),
            Text('Tháng ${_selectedDate.month}, ${_selectedDate.year}', style: AppText.labelLg()),
            const Spacer(),
            Text('Vuốt để xem thêm ngày', style: AppText.label(color: AppColor.textMuted)),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              final selected = _isSameDay(d, _selectedDate);
              final top = i == 0 ? 'HÔM NAY' : (i == 1 ? 'MAI' : Fmt.weekdayShort(d));
              return Material(
                color: selected ? AppColor.primaryDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: selected ? 2 : 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (selected) return;
                    setState(() => _selectedDate = d);
                    _reloadBookings();
                  },
                  child: Container(
                    width: i == 0 ? 76 : 60,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: selected ? null : Border.all(color: AppColor.border)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(top, style: AppText.labelSm(color: selected ? const Color(0xFFCFF5D6) : AppColor.textMuted)),
                      const SizedBox(height: 2),
                      Text('${d.day}', style: AppText.stat(size: 22, color: selected ? Colors.white : AppColor.text)),
                      if (i < 2) Text(Fmt.weekdayShort(d), style: AppText.labelSm(color: selected ? const Color(0xFFCFF5D6) : AppColor.textMuted)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  /// Bảng giá công khai, gộp các sân có cùng bảng giá.
  void _showPriceTable() {
    final groups = <String, List<SanModel>>{};
    for (final s in _sanList) {
      final key = '${s.gia}|${s.bangGia.map((r) => '${r.thu}${r.tuGio}${r.denGio}${r.gia}').join(';')}';
      (groups[key] ??= []).add(s);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
          const SzSheetHandle(),
          const SzSheetHeader(title: 'Bảng giá theo khung giờ', subtitle: 'Giá mỗi giờ, thay đổi theo ngày và giờ chơi', icon: Icons.price_change_outlined),
          const SizedBox(height: 14),
          for (final courts in groups.values) ...[
            Text(courts.map((c) => c.tenSan).join(', '), style: AppText.headlineSm()),
            const SizedBox(height: 8),
            for (final r in courts.first.bangGia) _priceTableRow(r.ten ?? 'Khung giá', '${r.daysLabel} · ${r.tuGio}–${r.denGio}', r.gia, courts.first.gia),
            _priceTableRow('Giờ còn lại', 'Giá mặc định', courts.first.gia, courts.first.gia),
            const SizedBox(height: 14),
          ],
        ]),
      ),
    );
  }

  Widget _priceTableRow(String title, String subtitle, double gia, double base) {
    final peak = gia > base, cheap = gia < base;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: peak ? const Color(0xFFFFF7E6) : cheap ? const Color(0xFFEEFAF2) : AppColor.canvas, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppText.labelLg()), Text(subtitle, style: AppText.bodySm())])),
        Text('${Fmt.money(gia)}/h', style: AppText.headlineSm(color: peak ? const Color(0xFFB45309) : AppColor.primaryDark)),
      ]),
    );
  }

  Widget _buildLegend() {
    Widget item(Widget swatch, String label, {bool strong = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: strong ? AppText.labelLg(color: AppColor.primaryDark) : AppText.body(color: AppColor.textMuted)),
        ]);
    Widget box({Color color = Colors.white, Color border = AppColor.border, Widget? child}) =>
        Container(width: 18, height: 18, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), border: Border.all(color: border)), child: child);

    return Container(
      color: AppColor.canvas,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(children: [
        Wrap(spacing: 16, runSpacing: 8, children: [
          item(box(), 'Trống'),
          item(box(color: AppColor.primaryDark, border: AppColor.primaryDark, child: const Icon(Icons.check_rounded, size: 13, color: Colors.white)), 'Đang chọn', strong: true),
          item(box(color: const Color(0xFFE2E8F0), border: const Color(0xFFCBD5E1), child: CustomPaint(painter: _HatchPainter())), 'Đã đặt'),
          item(box(color: AppColor.slot, child: const Icon(Icons.lock_rounded, size: 11, color: AppColor.textSubtle)), 'Đã qua'),
          if (_sanList.any((s) => s.hasTimePricing)) ...[
            item(box(color: const Color(0xFFFFF7E6), border: const Color(0xFFFCD9A0)), 'Giờ cao điểm'),
            item(box(color: const Color(0xFFEEFAF2), border: const Color(0xFFA7DFBA)), 'Giờ ưu đãi'),
          ],
        ]),
        if (_sanList.any((s) => s.hasTimePricing))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SzButton.small('Xem bảng giá theo khung giờ', icon: Icons.price_change_outlined, kind: SzButtonKind.soft, expand: true, onPressed: _showPriceTable),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Row(children: [
            const Icon(Icons.touch_app_outlined, size: 18, color: AppColor.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Chạm để chọn các khung giờ 30 phút liền nhau', style: AppText.label(color: AppColor.primaryDark))),
            Text('Bước: 30p', style: AppText.label(color: AppColor.textMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    final slotsForHeader = _slotMap[_sanList.first.maSan] ?? const <TimeSlot>[];
    const headerHeight = 44.0;
    const rowHeight = _cellHeight + 16;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SzCard(
        padding: EdgeInsets.zero,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cột tên sân (ghim cố định)
          Container(
            width: _nameColWidth,
            decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppColor.border))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: headerHeight,
                color: AppColor.canvas,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text('TÊN SÂN', style: AppText.labelSm()),
              ),
              for (final san in _sanList)
                Container(
                  height: rowHeight,
                  color: san.maSan == _selectedMaSan ? AppColor.mint : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (san.maSan == _selectedMaSan) ...[Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColor.primary, shape: BoxShape.circle)), const SizedBox(width: 4)],
                      Flexible(child: Text(san.tenSan, style: AppText.headlineSm(color: san.maSan == _selectedMaSan ? AppColor.primaryDark : AppColor.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Text(san.minRate == san.maxRate ? '${_compactPrice(san.gia)}/h' : '${_compactPrice(san.minRate)}–${_compactPrice(san.maxRate)}', style: AppText.label(color: AppColor.primary)),
                  ]),
                ),
            ]),
          ),
          // Lưới ô 30 phút (cuộn ngang)
          Expanded(
            child: SingleChildScrollView(
              controller: _gridScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(children: [
                    for (final s in slotsForHeader)
                      Container(
                        width: _cellWidth,
                        margin: const EdgeInsets.only(right: _cellGap),
                        alignment: Alignment.center,
                        child: Text(Fmt.hhmm(s.start), style: _isSelectedTime(s.start) ? AppText.labelLg(color: AppColor.primaryDark).copyWith(fontWeight: FontWeight.w800) : AppText.label(color: AppColor.textMuted)),
                      ),
                  ]),
                ),
                for (final san in _sanList)
                  SizedBox(
                    height: rowHeight,
                    child: Row(children: [
                      for (final slot in _slotMap[san.maSan] ?? const <TimeSlot>[])
                        Padding(
                          padding: const EdgeInsets.only(right: _cellGap),
                          child: _SlotCell(
                            slot: slot,
                            width: _cellWidth,
                            height: _cellHeight,
                            selected: san.maSan == _selectedMaSan && _selectedStarts.contains(slot.start),
                            priceLabel: _compactPrice(san.rateAt(slot.start) / 2),
                            tier: san.rateAt(slot.start).compareTo(san.gia),
                            onTap: () => _onSlotTap(slot),
                          ),
                        ),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  bool _isSelectedTime(DateTime t) => _selectedStarts.contains(t);

  /// 100000 → "100k"; 125000 → "125k"; 1500000 → "1,5tr"
  String _compactPrice(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1).replaceAll('.', ',')}tr';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1).replaceAll('.', ',')}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildSummaryBar() {
    final sel = _selection;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadow.sticky),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: sel == null
          ? Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColor.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Chọn khung giờ trống trên lưới để đặt sân', style: AppText.body(color: AppColor.textMuted))),
              const SizedBox(width: 8),
              const SzButton('ĐẶT SÂN', onPressed: null, height: 48),
            ])
          : Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                    SzPill(sel.san.tenSan),
                    Text('${sel.thoiGianHienThi}  ·  ${Fmt.hoursCount(sel.tongGio)}', style: AppText.label()),
                  ]),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.money(sel.tongTien), style: AppText.stat(size: 26, color: AppColor.primaryDark))),
                ]),
              ),
              const SizedBox(width: 12),
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                SzButton('ĐẶT SÂN', kind: SzButtonKind.dark, height: 52, trailingIcon: Icons.arrow_forward_rounded, onPressed: _openConfirm),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => setState(_clearSelection),
                  child: Text('Bỏ chọn', style: AppText.label(color: AppColor.textMuted)),
                ),
              ]),
            ]),
    );
  }
}

class _SlotCell extends StatelessWidget {
  final TimeSlot slot;
  final double width;
  final double height;
  final bool selected;
  final String priceLabel;

  /// So với giá mặc định: 1 = cao điểm, -1 = ưu đãi, 0 = thường.
  final int tier;
  final VoidCallback onTap;

  const _SlotCell({required this.slot, required this.width, required this.height, required this.selected, required this.priceLabel, this.tier = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColor.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: const Color(0xFF7FDA91), width: 2),
            boxShadow: AppShadow.primaryGlow,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(height: 2),
            Text(Fmt.hhmm(slot.start), style: AppText.label(color: Colors.white).copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
    }
    switch (slot.status) {
      case SlotStatus.booked:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(AppRadius.sm)),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(painter: _HatchPainter(), child: Center(child: Text('Đã đặt', style: AppText.label(color: AppColor.textMuted)))),
        );
      case SlotStatus.locked:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: AppColor.slot, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColor.textSubtle),
        );
      default:
        final (bg, border, fg) = switch (tier) {
          1 => (const Color(0xFFFFF7E6), const Color(0xFFFCD9A0), const Color(0xFFB45309)),
          -1 => (const Color(0xFFEEFAF2), const Color(0xFFA7DFBA), AppColor.primaryDark),
          _ => (Colors.white, AppColor.border, AppColor.text),
        };
        return Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: border)),
              child: Text(priceLabel, style: AppText.labelLg(color: fg)),
            ),
          ),
        );
    }
  }
}

/// Sọc chéo cho ô "Đã đặt".
class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// M8 – Xác nhận đặt sân.
class _ConfirmSheet extends StatelessWidget {
  final CumSanModel cumSan;
  final BookingSelection selection;
  final VoidCallback onConfirm;

  const _ConfirmSheet({required this.cumSan, required this.selection, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final sel = selection;
    final slots = (sel.duration.inMinutes / 30).round();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SzSheetHandle(),
          const SizedBox(height: 4),
          const SzSheetHeader(icon: Icons.sports_tennis_rounded, title: 'Xác nhận đặt sân', subtitle: 'Kiểm tra thông tin trước khi thanh toán'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColor.canvas,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: const Border(top: BorderSide(color: AppColor.primary, width: 4)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stadium_outlined, color: AppColor.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cumSan.tenCumSan, style: AppText.headlineSm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColor.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(cumSan.diaChi, style: AppText.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('CHI TIẾT LỊCH', style: AppText.labelSm())),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 10),
              _box(Row(children: [
                const Icon(Icons.grid_view_rounded, size: 18, color: AppColor.primary),
                const SizedBox(width: 8),
                Text('Sân thi đấu', style: AppText.body(color: AppColor.textMuted)),
                const Spacer(),
                Text(sel.san.tenSan, style: AppText.headlineSm()),
              ])),
              const SizedBox(height: 8),
              _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Text('Thời gian', style: AppText.body(color: AppColor.textMuted)),
                  const Spacer(),
                  SzPill('${Fmt.hoursCount(sel.tongGio)} / $slots khung giờ'),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 26),
                  Expanded(child: Text(Fmt.dateLong(sel.batDau), style: AppText.labelLg())),
                  const Icon(Icons.schedule_rounded, size: 18, color: AppColor.primary),
                  const SizedBox(width: 4),
                  Text(sel.thoiGianHienThi, style: AppText.headlineSm(color: AppColor.primary)),
                ]),
              ])),
              const SizedBox(height: 10),
              ..._priceRows(sel),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tổng tiền tạm tính', style: AppText.labelLg()),
                    Text('Áp dụng voucher ở bước thanh toán', style: AppText.bodySm()),
                  ]),
                ),
                Text(Fmt.money(sel.tongTien), style: AppText.stat(size: 26, color: AppColor.primaryDark)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, color: AppColor.pending, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Khung giờ sẽ được giữ cho bạn trong lúc hoàn tất thanh toán ở bước tiếp theo.', style: AppText.bodySm(color: AppColor.text))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(flex: 2, child: SzButton('Huỷ', kind: SzButtonKind.soft, onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 10),
            Expanded(flex: 5, child: SzButton('Xác nhận đặt sân', uppercase: true, trailingIcon: Icons.arrow_forward_rounded, onPressed: onConfirm)),
          ]),
        ]),
      ),
    );
  }

  /// Đơn giá: một dòng nếu cả lượt cùng giá, ngược lại chia theo từng khung giờ.
  List<Widget> _priceRows(BookingSelection sel) {
    final parts = sel.san.breakdown(sel.batDau, sel.ketThuc);
    if (parts.length <= 1) {
      final p = parts.isEmpty ? null : parts.first;
      return [
        Row(children: [
          Text('Đơn giá áp dụng:', style: AppText.body(color: AppColor.textMuted)),
          const Spacer(),
          Text('${Fmt.money(p?.gia ?? sel.san.gia)}/giờ${p?.ten != null ? ' · ${p!.ten}' : ''}', style: AppText.labelLg()),
        ]),
      ];
    }
    return [
      Text('Đơn giá theo khung giờ', style: AppText.body(color: AppColor.textMuted)),
      const SizedBox(height: 6),
      for (final p in parts)
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: p.gia > sel.san.gia ? const Color(0xFFFFF7E6) : p.gia < sel.san.gia ? const Color(0xFFEEFAF2) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(children: [
            Expanded(child: Text('${Fmt.range(p.from, p.to)}${p.ten != null ? ' · ${p.ten}' : ''}', style: AppText.label(color: p.gia > sel.san.gia ? const Color(0xFFB45309) : AppColor.text))),
            Text('${Fmt.money(p.gia)}/h', style: AppText.bodySm()),
            const SizedBox(width: 10),
            Text(Fmt.money(p.amount), style: AppText.labelLg()),
          ]),
        ),
    ];
  }

  Widget _box(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: child,
      );
}
