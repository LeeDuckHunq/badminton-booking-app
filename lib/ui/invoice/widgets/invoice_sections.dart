// lib/ui/invoice/widgets/invoice_sections.dart

import 'dart:io';

import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:application/ui/theme/app_color.dart';
import '../models/invoice_model.dart';

// ─── Section Header ───────────────────────────────────────────────────────────
class InvoiceSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const InvoiceSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColor.kLineWhite, size: 15),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColor.kTextDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── White Card Container ─────────────────────────────────────────────────────
class InvoiceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const InvoiceCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

// ─── Row thông tin ────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColor.kTextDark,
                fontSize: 13,
                fontWeight: valueFontWeight ?? FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 1. Thông tin người dùng ──────────────────────────────────────────────────
class UserInfoSection extends StatelessWidget {
  final UserModel? userInfo;
  final bool isLoading;

  const UserInfoSection({
    super.key,
    required this.userInfo,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.person_outline_rounded,
          title: 'Thông tin người đặt',
        ),
        InvoiceCard(
          child: isLoading
              ? _loadingPlaceholder()
              : userInfo == null
              ? _emptyPlaceholder()
              : Column(
            children: [
              InfoRow(
                  label: 'Họ và tên',
                  value: userInfo!.fullName),
              InfoRow(
                  label: 'Số điện thoại',
                  value: userInfo!.phoneNumber),
              InfoRow(label: 'Email', value: userInfo!.email),
              InfoRow(
                  label: 'Mã người dùng',
                  value: userInfo!.username,
                  valueColor: Colors.grey[400],
                  valueFontWeight: FontWeight.w400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadingPlaceholder() => const Center(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: CircularProgressIndicator(
          color: AppColor.kCourtGreen, strokeWidth: 2),
    ),
  );

  Widget _emptyPlaceholder() => Text('Đang tải thông tin...',
      style: TextStyle(color: Colors.grey[400], fontSize: 13));
}

// ─── 2. Thông tin đặt sân ─────────────────────────────────────────────────────
class BookingInfoSection extends StatelessWidget {
  final InvoiceBookingInfo booking;

  const BookingInfoSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.sports_tennis_rounded,
          title: 'Thông tin đặt sân',
        ),
        InvoiceCard(
          child: Column(
            children: [
              // Header sân
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_tennis_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.tenCumSan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            booking.tenSan,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
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
                        booking.ngayDat,
                        style: const TextStyle(
                          color: AppColor.kDeepGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              InfoRow(
                  label: 'Địa chỉ',
                  value: booking.diaChi),
              InfoRow(
                  label: 'Khung giờ',
                  value: booking.thoiGian,
                  valueColor: AppColor.kCourtGreen,
                  valueFontWeight: FontWeight.w700),
              InfoRow(
                  label: 'Thời lượng',
                  value: '${_fmtHours(booking.tongGio)} giờ'),

              const Divider(height: 20),

              // Tổng tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền gốc',
                      style: TextStyle(
                          color: AppColor.kTextDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  Text(
                    _fmtCurrency(booking.tongTien),
                    style: const TextStyle(
                      color: AppColor.kTextDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

// ─── 3. Danh sách khuyến mãi ─────────────────────────────────────────────────
class PromoSection extends StatelessWidget {
  final List<KhuyenMaiModel> promoList;
  final String? selectedMaKhuyenMai;
  final ValueChanged<String?> onSelected;
  final bool isLoading;

  const PromoSection({
    super.key,
    required this.promoList,
    required this.selectedMaKhuyenMai,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.local_offer_outlined,
          title: 'Khuyến mãi',
        ),
        if (isLoading)
          InvoiceCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    color: AppColor.kCourtGreen, strokeWidth: 2),
              ),
            ),
          )
        else if (promoList.isEmpty)
          InvoiceCard(
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined,
                    color: Colors.grey[300], size: 20),
                const SizedBox(width: 10),
                Text('Không có khuyến mãi áp dụng',
                    style:
                    TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          )
        else
          Column(
            children: promoList.map((promo) {
              final isSelected =
                  selectedMaKhuyenMai == promo.maKhuyenMai;
              return GestureDetector(
                onTap: () => onSelected(
                    isSelected ? null : promo.maKhuyenMai),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.kMintField
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColor.kCourtGreen
                          : Colors.grey[200]!,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Discount badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColor.kCourtGreen
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '-${(promo.phanTramGiam * 100).toInt()}%',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.tenKhuyenMai,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColor.kCourtGreen
                                    : AppColor.kTextDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Sử dụng ngay!",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'HSD: ${promo.ngayKetThuc}',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColor.kCourtGreen
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColor.kCourtGreen
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 13)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─── 4. Tài khoản ngân hàng ───────────────────────────────────────────────────
class BankAccountSection extends StatelessWidget {
  final List<BankAccountModel> bankList;
  final bool isLoading;

  const BankAccountSection({
    super.key,
    required this.bankList,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.account_balance_outlined,
          title: 'Tài khoản nhận tiền',
        ),
        if (isLoading)
          InvoiceCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    color: AppColor.kCourtGreen, strokeWidth: 2),
              ),
            ),
          )
        else
          Column(
            children: bankList.map((bank) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Bank logo / icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColor.kMintField,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green[100]!, width: 1),
                      ),
                      child: bank.logoUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(bank.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(
                                Icons.account_balance_rounded,
                                color: AppColor.kCourtGreen,
                                size: 22)),
                      )
                          : const Icon(Icons.account_balance_rounded,
                          color: AppColor.kCourtGreen, size: 22),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.tenNganHang,
                            style: const TextStyle(
                              color: AppColor.kTextDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bank.soTaiKhoan,
                            style: const TextStyle(
                              color: AppColor.kCourtGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            bank.chuTaiKhoan,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),

                    // Copy STK button
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: bank.soTaiKhoan));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã sao chép số tài khoản'),
                            backgroundColor: AppColor.kCourtGreen,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.kMintField,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_rounded,
                            color: AppColor.kCourtGreen, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─── 5. QR Code ───────────────────────────────────────────────────────────────
class QrCodeSection extends StatelessWidget {
  final String? qrImageUrl;
  final bool isLoading;

  const QrCodeSection({
    super.key,
    required this.qrImageUrl,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.qr_code_rounded,
          title: 'Mã QR thanh toán',
        ),
        InvoiceCard(
          child: isLoading
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: AppColor.kCourtGreen, strokeWidth: 2),
            ),
          )
              : qrImageUrl == null
              ? _emptyQr()
              : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey[200]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    qrImageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _emptyQr(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Quét mã QR để chuyển khoản',
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyQr() {
    return Column(
      children: [
        Icon(Icons.qr_code_rounded, color: Colors.grey[300], size: 64),
        const SizedBox(height: 8),
        Text('Chưa có mã QR',
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ],
    );
  }
}

// ─── 6. Bill Upload Section ───────────────────────────────────────────────────
class BillUploadSection extends StatelessWidget {
  final File? billFile;            // File local sau khi pick
  final String? uploadedUrl;       // URL sau khi upload lên Supabase
  final bool isUploading;
  final VoidCallback onPickImage;

  const BillUploadSection({
    super.key,
    required this.billFile,
    required this.uploadedUrl,
    required this.isUploading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InvoiceSectionHeader(
          icon: Icons.upload_file_rounded,
          title: 'Tải lên bill thanh toán',
        ),
        InvoiceCard(
          padding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: isUploading ? null : onPickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: uploadedUrl != null
                      ? AppColor.kCourtGreen
                      : Colors.grey[300]!,
                  width: uploadedUrl != null ? 1.5 : 1,
                ),
              ),
              child: isUploading
                  ? const Column(
                children: [
                  CircularProgressIndicator(
                      color: AppColor.kCourtGreen, strokeWidth: 2.5),
                  SizedBox(height: 10),
                  Text('Đang tải ảnh lên...',
                      style: TextStyle(
                          color: AppColor.kCourtGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              )
                  : billFile != null
                  ? _uploadedContent()
                  : _emptyUpload(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyUpload() {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColor.kMintField,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: AppColor.kCourtGreen, size: 28),
        ),
        const SizedBox(height: 10),
        const Text(
          'Chụp hoặc chọn ảnh bill',
          style: TextStyle(
            color: AppColor.kTextDark,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hỗ trợ JPG, PNG • Tối đa 5MB',
          style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _uploadedContent() {
    return Column(
      children: [
        // Preview ảnh từ file local (dùng Image.file)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            billFile!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        if (uploadedUrl != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: AppColor.kCourtGreen, size: 16),
              SizedBox(width: 5),
              Text('Đã tải lên thành công',
                  style: TextStyle(
                    color: AppColor.kCourtGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  )),
            ],
          )
        else
          Text('Nhấn để đổi ảnh',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}