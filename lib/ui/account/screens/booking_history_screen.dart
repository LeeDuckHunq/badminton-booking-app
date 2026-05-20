// lib/ui/account/screens/booking_history_screen.dart

import 'package:application/model/cum_san_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingHistoryScreen extends StatefulWidget {
  final List<PhieuDatSanModel> phieuList;
  final List<SanModel> sanList;
  final List<CumSanModel> cumSanList;

  const BookingHistoryScreen({
    super.key,
    required this.phieuList,
    required this.sanList,
    required this.cumSanList,
  });

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _tabs = const ['Tất cả', 'Chờ xác nhận', 'Đã xác nhận'];

  List<PhieuDatSanModel> _filtered(String tab) {
    if (tab == 'Chờ xác nhận') {
      return widget.phieuList
          .where((p) => p.trangThai == 'CHO_XAC_NHAN')
          .toList();
    }
    if (tab == 'Đã xác nhận') {
      return widget.phieuList
          .where((p) => p.trangThai == 'DA_XAC_NHAN')
          .toList();
    }
    return widget.phieuList;
  }

  SanModel? _getSan(String maSan) =>
      widget.sanList.where((s) => s.maSan == maSan).firstOrNull;

  CumSanModel? _getCumSan(String maCumSan) =>
      widget.cumSanList.where((c) => c.maCumSan == maCumSan).firstOrNull;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _tabs
                  .map((tab) => _buildList(_filtered(tab)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

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
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.kLineWhite, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sân đã đặt',
                        style: TextStyle(
                          color: AppColor.kLineWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        )),
                    Text('Lịch sử đặt sân của bạn',
                        style:
                        TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.kAccentYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.phieuList.length} phiếu',
                  style: const TextStyle(
                    color: AppColor.kDeepGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColor.kCourtGreen,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: AppColor.kCourtGreen,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildList(List<PhieuDatSanModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis_rounded,
                color: Colors.grey[300], size: 52),
            const SizedBox(height: 12),
            Text('Không có phiếu đặt nào',
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final phieu = list[i];
        final san = _getSan(phieu.maSan);
        final cumSan =
        san != null ? _getCumSan(san.maCumSan) : null;

        return _PhieuDatCard(
          phieu: phieu,
          san: san,
          cumSan: cumSan,
          onViewInvoice: () => _showInvoiceSheet(context, phieu, san, cumSan),
        );
      },
    );
  }

  void _showInvoiceSheet(
      BuildContext context,
      PhieuDatSanModel phieu,
      SanModel? san,
      CumSanModel? cumSan,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(
          phieu: phieu, san: san, cumSan: cumSan),
    );
  }
}

// ── Phiếu đặt card ────────────────────────────────────────────────────────────
class _PhieuDatCard extends StatelessWidget {
  final PhieuDatSanModel phieu;
  final SanModel? san;
  final CumSanModel? cumSan;
  final VoidCallback onViewInvoice;

  const _PhieuDatCard({
    required this.phieu,
    required this.san,
    required this.cumSan,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(phieu.trangThai);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusInfo.$3.withOpacity(0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusInfo.$3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusInfo.$2,
                      color: statusInfo.$3, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cumSan?.tenCumSan ?? 'Cụm sân',
                        style: const TextStyle(
                          color: AppColor.kTextDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        '#${phieu.maPhieuDat}',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.$3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                _infoRow(Icons.sports_tennis_rounded,
                    san?.tenSan ?? phieu.maSan,
                    AppColor.kCourtGreen),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined,
                    cumSan?.diaChi ?? '---',
                    Colors.grey[500]!),
                const SizedBox(height: 6),
                _infoRow(Icons.access_time_rounded,
                    '${_fmtTime(phieu.batDau)} – ${_fmtTime(phieu.ketThuc)}  •  ${_fmtDate(phieu.batDau)}',
                    Colors.grey[500]!),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 20),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng tiền',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11.5)),
                    Text(
                      _fmtCurrency(phieu.tongTien),
                      style: const TextStyle(
                        color: AppColor.kCourtGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onViewInvoice,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColor.kDeepGreen,
                          AppColor.kCourtGreen
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Xem hóa đơn',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: Colors.grey[700], fontSize: 12.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  (String, IconData, Color) _statusInfo(String status) {
    switch (status) {
      case 'DA_XAC_NHAN':
        return ('Đã xác nhận', Icons.check_circle_rounded,
        AppColor.kCourtGreen);
      case 'CHO_XAC_NHAN':
        return ('Chờ xác nhận', Icons.access_time_rounded,
        const Color(0xFFFF8F00));
      case 'DA_HUY':
        return ('Đã huỷ', Icons.cancel_rounded, Colors.red);
      default:
        return ('Không xác định', Icons.help_outline_rounded,
        Colors.grey);
    }
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

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

// ── Invoice detail bottom sheet ───────────────────────────────────────────────
class _InvoiceDetailSheet extends StatelessWidget {
  final PhieuDatSanModel phieu;
  final SanModel? san;
  final CumSanModel? cumSan;

  const _InvoiceDetailSheet({
    required this.phieu,
    required this.san,
    required this.cumSan,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text('Chi tiết hóa đơn',
                    style: TextStyle(
                      color: AppColor.kTextDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 22),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 20),
              child: Column(
                children: [
                  _invoiceCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_tennis_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cumSan?.tenCumSan ?? 'Cụm sân',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        san?.tenSan ?? phieu.maSan,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.kAccentYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${phieu.maPhieuDat}',
                    style: const TextStyle(
                      color: AppColor.kDeepGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _detailRow('Địa chỉ', cumSan?.diaChi ?? '---'),
                _detailRow('Ngày đặt', _fmtDate(phieu.ngayLap)),
                _detailRow('Khung giờ',
                    '${_fmtTime(phieu.batDau)} – ${_fmtTime(phieu.ketThuc)}',
                    valueColor: AppColor.kCourtGreen),
                _detailRow('Ngày chơi', _fmtDate(phieu.batDau)),
                if (phieu.maKhuyenMai != null)
                  _detailRow('Mã KM', phieu.maKhuyenMai!,
                      valueColor: Colors.orange[700]!),
                _detailRow('Trạng thái', _statusLabel(phieu.trangThai),
                    valueColor: _statusColor(phieu.trangThai)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền',
                        style: TextStyle(
                          color: AppColor.kTextDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                    Text(
                      _fmtCurrency(phieu.tongTien),
                      style: const TextStyle(
                        color: AppColor.kCourtGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Copy mã phiếu
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: phieu.maPhieuDat));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã sao chép mã phiếu'),
                        backgroundColor: AppColor.kCourtGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColor.kMintField,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.green[200]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.copy_rounded,
                            color: AppColor.kCourtGreen, size: 14),
                        SizedBox(width: 6),
                        Text('Sao chép mã phiếu',
                            style: TextStyle(
                              color: AppColor.kCourtGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: valueColor ?? AppColor.kTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'DA_XAC_NHAN':  return 'Đã xác nhận';
      case 'CHO_XAC_NHAN': return 'Chờ xác nhận';
      case 'DA_HUY':       return 'Đã huỷ';
      default:             return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DA_XAC_NHAN':  return AppColor.kCourtGreen;
      case 'CHO_XAC_NHAN': return const Color(0xFFFF8F00);
      case 'DA_HUY':       return Colors.red;
      default:             return Colors.grey;
    }
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

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