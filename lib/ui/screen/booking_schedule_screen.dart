// lib/ui/booking/booking_schedule_screen.dart

import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/model/create_phieu_dat_model.dart';
import 'package:application/model/cum_san_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/ui/screen/invoice_screen.dart';
import 'package:application/ui/invoice/models/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../booking/models/booking_state.dart';
import '../booking/widgets/booking_date_picker.dart';
import '../booking/widgets/booking_grid.dart';
import '../booking/widgets/booking_legend.dart';
import '../booking/widgets/booking_summary_bar.dart';

class BookingScheduleScreen extends StatefulWidget {
  final CumSanModel cumSan;

  const BookingScheduleScreen({super.key, required this.cumSan});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  // ── Data ──────────────────────────────────────────────────────────────────
  List<SanModel> _sanList = [];
  List<PhieuDatSanModel> _phieuList = [];

  bool _isLoading = true;
  String? _errorMsg;

  // ── User ──────────────────────────────────────────────────────────────────
  String _maNguoiDung = '';

  // ── Date selection ────────────────────────────────────────────────────────
  late DateTime _selectedDate;

  // ── Slot selection ────────────────────────────────────────────────────────
  String? _selectedMaSan;
  final Set<DateTime> _selectedStarts = {};

  // ── Computed ──────────────────────────────────────────────────────────────
  Map<String, List<TimeSlot>> _slotMap = {};
  BookingSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
    _loadUser();
    _loadData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _maNguoiDung = prefs.getString('username') ?? '');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  DateTime _toDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final results = await Future.wait([
        SanApi.getSanTheoCumSan(widget.cumSan.maCumSan),
        PhieuDatSanApi.getPhieuDatTheoNgay(_selectedDate),
      ]);

      _sanList   = results[0] as List<SanModel>;
      _phieuList = results[1] as List<PhieuDatSanModel>;

      _buildSlotMap();
    } catch (e) {
      _errorMsg = 'Không thể tải dữ liệu. Vui lòng thử lại.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Chỉ load lại lịch đặt khi đổi ngày (không cần load lại sân)
  Future<void> _reloadBookings() async {
    setState(() => _isLoading = true);

    try {
      _phieuList = await PhieuDatSanApi.getPhieuDatTheoNgay(_selectedDate);
      _clearSelection();
      _buildSlotMap();
    } catch (_) {
      _errorMsg = 'Không thể tải lịch đặt.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Slot map builder ──────────────────────────────────────────────────────

  /// Xây dựng map[maSan] → list TimeSlot dựa trên giờ mở/đóng cửa
  void _buildSlotMap() {
    final map = <String, List<TimeSlot>>{};

    final openTime  = _parseTime(widget.cumSan.gioMoCua);
    final closeTime = _parseTime(widget.cumSan.gioDongCua);

    final open  = _toDateTime(_selectedDate, openTime);
    final close = _toDateTime(_selectedDate, closeTime);

    // Chỉ tính những phiếu đã xác nhận là blocked
    final bookedMap = <String, List<(DateTime, DateTime)>>{};
    for (final p in _phieuList) {
      if (p.trangThai == 'DA_XAC_NHAN' || p.trangThai == 'CHO_XAC_NHAN') {
        bookedMap.putIfAbsent(p.maSan, () => []).add((p.batDau, p.ketThuc));
      }
    }

    for (final san in _sanList) {
      final slots = <TimeSlot>[];
      DateTime cur = open;

      while (cur.isBefore(close)) {
        final slotEnd = cur.add(const Duration(minutes: 30));

        // Kiểm tra xem slot này có bị đặt không
        final isBooked = (bookedMap[san.maSan] ?? []).any((range) {
          final (start, end) = range;
          // Overlap nếu start < slotEnd && end > cur
          return start.isBefore(slotEnd) && end.isAfter(cur);
        });

        // Slot trong quá khứ → locked
        final now = DateTime.now();
        final isPast = cur.isBefore(now) && _isSameDay(_selectedDate, _today());

        slots.add(TimeSlot(
          maSan: san.maSan,
          start: cur,
          end: slotEnd,
          status: isPast
              ? SlotStatus.locked
              : isBooked
              ? SlotStatus.booked
              : SlotStatus.available,
        ));

        cur = slotEnd;
      }

      map[san.maSan] = slots;
    }

    _slotMap = map;
  }

  // ── Selection logic ───────────────────────────────────────────────────────

  void _onSlotTap(TimeSlot slot) {
    setState(() {
      // Click vào sân khác → reset
      if (_selectedMaSan != null && _selectedMaSan != slot.maSan) {
        _clearSelection();
      }

      _selectedMaSan = slot.maSan;

      if (_selectedStarts.contains(slot.start)) {
        // Bỏ chọn ô đang chọn
        _selectedStarts.remove(slot.start);
        if (_selectedStarts.isEmpty) _selectedMaSan = null;
      } else {
        // Kiểm tra liên tiếp: ô mới phải kề với selection hiện tại
        if (_selectedStarts.isNotEmpty && !_isAdjacentToSelection(slot)) {
          // Reset và chọn lại từ ô này
          _selectedStarts.clear();
        }
        _selectedStarts.add(slot.start);
      }

      _updateSelection();
    });
  }

  bool _isAdjacentToSelection(TimeSlot slot) {
    if (_selectedStarts.isEmpty) return true;

    final sorted = _selectedStarts.toList()..sort();
    final earliest = sorted.first;
    final latest   = sorted.last;

    // Ô mới phải ngay trước earliest hoặc ngay sau latest
    final before = slot.start.add(const Duration(minutes: 30));
    final after  = slot.start.subtract(const Duration(minutes: 30));

    return before == earliest || after == latest;
  }

  void _updateSelection() {
    if (_selectedStarts.isEmpty || _selectedMaSan == null) {
      _currentSelection = null;
      return;
    }

    final san = _sanList.firstWhere((s) => s.maSan == _selectedMaSan);
    final sorted = _selectedStarts.toList()..sort();

    _currentSelection = BookingSelection(
      san: san,
      batDau: sorted.first,
      ketThuc: sorted.last.add(const Duration(minutes: 30)),
    );
  }

  void _clearSelection() {
    _selectedMaSan = null;
    _selectedStarts.clear();
    _currentSelection = null;
  }

  // ── Confirm booking ───────────────────────────────────────────────────────

  void _onConfirmBooking() {
    if (_currentSelection == null) return;
    _showConfirmDialog(_currentSelection!);
  }

  void _showConfirmDialog(BookingSelection sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmBottomSheet(
        selection: sel,
        onConfirm: () => _submitBooking(sel), // chỉ gọi submit, navigate bên trong
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  /// Gửi request tạo phiếu đặt — đứng im tại đây sau khi xong
  Future<void> _submitBooking(BookingSelection sel) async {
    // 1. Đóng bottom sheet
    Navigator.pop(context);

    // 2. Hiện loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Đang gửi yêu cầu đặt sân...'),
          ],
        ),
        backgroundColor: AppColor.kCourtGreen,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // 3. Gọi API — nhận về maPhieuDat
    final request = CreatePhieuDatModel(
      maNguoiDung: _maNguoiDung,
      maSan: sel.san.maSan,
      batDau: sel.batDau,
      ketThuc: sel.ketThuc,
    );

    final maPhieuDat = await PhieuDatSanApi.createPhieuDat(request);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 4. Xử lý kết quả
    if (maPhieuDat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Đặt sân thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 5. Navigate sang InvoiceScreen với đầy đủ dữ liệu
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceScreen(
          booking: InvoiceBookingInfo(
            maPhieuDat: maPhieuDat,         // ← từ API
            tenCumSan: widget.cumSan.tenCumSan,
            tenSan: sel.san.tenSan,
            diaChi: widget.cumSan.diaChi,
            batDau: sel.batDau,
            ketThuc: sel.ketThuc,
            tongTien: sel.tongTien,
          ),
          maPhieuDat: maPhieuDat,
        ),
      ),
    ).then((_) => setState(() {}));

    // 6. Reload lịch sân sau khi navigate
    setState(() => _clearSelection());
    await _reloadBookings();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(),
          _buildDatePicker(),
          const Divider(height: 1, color: Color(0xFFE8EDE9)),
          const BookingLegend(),
          const Divider(height: 1, color: Color(0xFFE8EDE9)),
          Expanded(child: _buildBody()),
          BookingSummaryBar(
            selection: _currentSelection,
            onConfirm: _onConfirmBooking,
            onClear: () => setState(() => _clearSelection()),
          ),
          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.kLineWhite, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cumSan.tenCumSan,
                      style: const TextStyle(
                        color: AppColor.kLineWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: Colors.white60, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.cumSan.gioMoCua} – ${widget.cumSan.gioDongCua}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white60, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.cumSan.diaChi,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Refresh
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColor.kLineWhite, size: 22),
                onPressed: _isLoading ? null : _reloadBookings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      color: AppColor.kLineWhite,
      child: BookingDatePicker(
        selectedDate: _selectedDate,
        onDateChanged: (date) {
          if (_isSameDay(date, _selectedDate)) return;
          setState(() => _selectedDate = date);
          _reloadBookings();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: AppColor.kCourtGreen, strokeWidth: 2.5),
            SizedBox(height: 14),
            Text('Đang tải lịch sân...',
                style: TextStyle(
                    color: AppColor.kCourtGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(_errorMsg!,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColor.kCourtGreen),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColor.kLineWhite,
      child: BookingGrid(
        sanList: _sanList,
        slotMap: _slotMap,
        selectedStarts: _selectedStarts,
        selectedMaSan: _selectedMaSan,
        onSlotTap: _onSlotTap,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Confirm Bottom Sheet ──────────────────────────────────────────────────────

class _ConfirmBottomSheet extends StatelessWidget {
  final BookingSelection selection;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmBottomSheet({
    required this.selection,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: const BoxDecoration(
        color: AppColor.kLineWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColor.kMintField,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: const Icon(Icons.sports_tennis_rounded,
                  color: AppColor.kCourtGreen, size: 32),
            ),

            const SizedBox(height: 16),

            const Text('Xác nhận đặt sân',
                style: TextStyle(
                  color: AppColor.kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                )),

            const SizedBox(height: 20),

            // Details
            _DetailRow(icon: Icons.sports_tennis_rounded,
                label: 'Sân', value: selection.san.tenSan),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.access_time_rounded,
                label: 'Thời gian', value: selection.thoiGianHienThi),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.timer_outlined,
                label: 'Tổng giờ',
                value: '${_fmtHours(selection.tongGio)} giờ'),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.payments_outlined,
                label: 'Tổng tiền',
                value: _fmtCurrency(selection.tongTien),
                valueColor: AppColor.kCourtGreen),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColor.kCourtGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Huỷ',
                        style: TextStyle(
                            color: AppColor.kCourtGreen,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kCourtGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Xác nhận đặt sân',
                        style: TextStyle(
                            color: AppColor.kLineWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtHours(double h) =>
      h == h.truncateToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColor.kMintField,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColor.kCourtGreen, size: 16),
        ),
        const SizedBox(width: 10),
        Text('$label:',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              color: valueColor ?? AppColor.kTextDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}