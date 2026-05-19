import 'dart:io';
import 'package:application/api/account_api.dart';
import 'package:application/api/hoa_don_api.dart';
import 'package:application/api/khuyen_mai_api.dart';
import 'package:application/model/hoa_don_request_model.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/user_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../invoice/models/invoice_model.dart';
import '../invoice/services/supabase_storage_service.dart';
import '../invoice/widgets/invoice_sections.dart';

class InvoiceScreen extends StatefulWidget {
  /// Thông tin đặt sân — truyền từ BookingScheduleScreen
  final InvoiceBookingInfo booking;

  final String maPhieuDat;

  const InvoiceScreen({
    super.key,
    required this.booking,
    required this.maPhieuDat
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // ── Data (đổ từ API sau) ──────────────────────────────────────────────────
  UserModel? _userInfo;
  List<KhuyenMaiModel> _promoList = [];
  List<BankAccountModel> _bankList = [];
  String? _qrImageUrl;

  bool _isLoadingUser  = true;
  bool _isLoadingPromo = true;
  bool _isLoadingBank  = true;
  bool _isLoadingQr    = true;

  // ── Promo selection ───────────────────────────────────────────────────────
  String? _selectedMaKhuyenMai;

  // ── Bill upload ───────────────────────────────────────────────────────────
  File? _billFile;
  String? _billUploadedUrl;
  bool _isUploading = false;

  // ── Confirm ───────────────────────────────────────────────────────────────
  bool _isConfirming = false;

  void loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? username = prefs.getString("username");

      if (username == null) {
        throw Exception("Không tìm thấy username");
      }

      _userInfo = await AccountApi.getUser(username);

      print(_userInfo?.fullName);
      print(_userInfo?.email);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    try {
      // ── Load User ─────────────────────────
      final prefs =
      await SharedPreferences
          .getInstance();

      String? username =
      prefs.getString("username");

      if (username == null) {
        throw Exception(
            "Không tìm thấy username");
      }

      UserModel user =
      await AccountApi
          .getUser(username);

      // ── Load khuyến mãi từ API ───────────
      List<KhuyenMaiModel> promoList =
      await KhuyenMaiApi
          .getKhuyenMaiTheoUser();

      print("PROMO COUNT: ${promoList.length}");

      for (var p in promoList) {
        print(p.maKhuyenMai);
        print(p.phanTramGiam);
      }

      // ── Mock bank list ───────────────────
      List<BankAccountModel> bankList = [
        const BankAccountModel(
          tenNganHang: 'MBBANK',
          soTaiKhoan: '0383222791',
          chuTaiKhoan:
          'LE NGUYEN VIET HUNG',
        ),
        const BankAccountModel(
          tenNganHang: 'MOMO',
          soTaiKhoan: '0383222791',
          chuTaiKhoan:
          'LE NGUYEN VIET HUNG',
        ),
      ];

      if (!mounted) return;

      setState(() {
        // User
        _userInfo = user;
        _isLoadingUser = false;

        // Promo
        _promoList = promoList;
        _isLoadingPromo = false;

        // Bank
        _bankList = bankList;
        _isLoadingBank = false;

        // QR
        _qrImageUrl =
        "https://drive.usercontent.google.com/download?id=153HvUP5xdjyjiBJdEJfVB0bszk0WKNer&export=view&authuser=0";
        _isLoadingQr = false;
      });

    } catch (e) {
      print("Lỗi load dữ liệu: $e");

      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
        _isLoadingPromo = false;
        _isLoadingBank = false;
        _isLoadingQr = false;
      });
    }
  }

  // ── Tính tổng tiền sau khuyến mãi ─────────────────────────────────────────
  double get _tongTienSauGiam {
    if (_selectedMaKhuyenMai == null) return widget.booking.tongTien;
    final promo = _promoList
        .where((p) => p.maKhuyenMai == _selectedMaKhuyenMai)
        .firstOrNull;
    if (promo == null) return widget.booking.tongTien;
    return widget.booking.tongTien * (1 - promo.phanTramGiam);
  }

  double get _soTienGiam =>
      widget.booking.tongTien - _tongTienSauGiam;

  // ── Pick + upload bill ─────────────────────────────────────────────────────
  Future<void> _pickAndUploadBill() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _billFile = File(picked.path);
      _isUploading = true;
      _billUploadedUrl = null;
    });

    final url = await SupabaseStorageService.uploadBillImage(
      file: _billFile!,
    );

    if (!mounted) return;

    setState(() {
      _billUploadedUrl = url;
      _isUploading = false;
    });

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Tải ảnh thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColor.kMintField,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColor.kCourtGreen),
              ),
              title: const Text('Chụp ảnh',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColor.kMintField,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColor.kCourtGreen),
              ),
              title: const Text('Chọn từ thư viện',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            SizedBox(
                height:
                MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ── Confirm booking ────────────────────────────────────────────────────────
  Future<void> _confirmBooking() async {
    if (_billUploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Vui lòng tải lên bill thanh toán trước khi xác nhận'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);

    final now = DateTime.now();
    final ngayLap = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}'
        'T${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';

    final request = CreateHoaDonRequest(
      maHoaDon: 'HD${now.millisecondsSinceEpoch}',  // auto generate
      maPhieuDat: widget.maPhieuDat,
      maKhuyenMai: _selectedMaKhuyenMai,
      tongTien: _tongTienSauGiam,
      ngayLap: ngayLap,
      billThanhToan: _billUploadedUrl!,
    );

    final success = await HoaDonApi.createHoaDon(request);

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🏸 Đặt sân thành công! Chúng tôi sẽ xác nhận sớm.'),
          backgroundColor: AppColor.kCourtGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Tạo hóa đơn thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          _buildBottomBar(),
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
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
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
                    Text(
                      'Hóa đơn đặt sân',
                      style: TextStyle(
                        color: AppColor.kLineWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kiểm tra thông tin và xác nhận',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              // Invoice badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.kAccentYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'CHỜ XÁC NHẬN',
                  style: TextStyle(
                    color: AppColor.kDeepGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 1. Thông tin người đặt ───────────────────────────────────────
        UserInfoSection(
            userInfo: _userInfo, isLoading: _isLoadingUser),
        const SizedBox(height: 20),

        // ── 2. Thông tin đặt sân ─────────────────────────────────────────
        BookingInfoSection(booking: widget.booking),
        const SizedBox(height: 20),

        // ── 3. Khuyến mãi ────────────────────────────────────────────────
        PromoSection(
          promoList: _promoList,
          selectedMaKhuyenMai: _selectedMaKhuyenMai,
          onSelected: (ma) => setState(() => _selectedMaKhuyenMai = ma),
          isLoading: _isLoadingPromo,
        ),
        const SizedBox(height: 20),

        // ── 4. Tài khoản ngân hàng ───────────────────────────────────────
        BankAccountSection(
            bankList: _bankList, isLoading: _isLoadingBank),
        const SizedBox(height: 20),

        // ── 5. QR Code ───────────────────────────────────────────────────
        QrCodeSection(
            qrImageUrl: _qrImageUrl, isLoading: _isLoadingQr),
        const SizedBox(height: 20),

        // ── 6. Upload bill ───────────────────────────────────────────────
        BillUploadSection(
          billFile: _billFile,
          uploadedUrl: _billUploadedUrl,
          isUploading: _isUploading,
          onPickImage: _pickAndUploadBill,
        ),
        const SizedBox(height: 20),

        // ── Tổng tiền summary ────────────────────────────────────────────
        _buildPriceSummary(),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return InvoiceCard(
      child: Column(
        children: [
          // Tiêu đề
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: AppColor.kCourtGreen, size: 18),
              SizedBox(width: 8),
              Text('Tổng kết thanh toán',
                  style: TextStyle(
                      color: AppColor.kTextDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _summaryRow('Tiền sân', widget.booking.tongTien),

          if (_selectedMaKhuyenMai != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        color: Colors.green, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      'Khuyến mãi',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '- ${_fmtCurrency(_soTienGiam)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán',
                  style: TextStyle(
                    color: AppColor.kTextDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  )),
              Text(
                _fmtCurrency(_tongTienSauGiam),
                style: const TextStyle(
                  color: AppColor.kCourtGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(_fmtCurrency(amount),
            style: const TextStyle(
                color: AppColor.kTextDark,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }

  // ── Bottom confirm bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final hasUpload = _billUploadedUrl != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tổng tiền mini
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cần thanh toán',
                    style:
                    TextStyle(color: Colors.grey[500], fontSize: 11.5)),
                Text(
                  _fmtCurrency(_tongTienSauGiam),
                  style: const TextStyle(
                    color: AppColor.kCourtGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Confirm button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isConfirming || _isUploading)
                  ? null
                  : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasUpload
                    ? AppColor.kCourtGreen
                    : Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: _isConfirming
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasUpload
                        ? Icons.check_circle_outline_rounded
                        : Icons.upload_file_rounded,
                    color: hasUpload
                        ? Colors.white
                        : Colors.grey[500],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasUpload ? 'XÁC NHẬN ĐẶT SÂN' : 'TẢI BILL TRƯỚC',
                    style: TextStyle(
                      color: hasUpload
                          ? Colors.white
                          : Colors.grey[500],
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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