// lib/ui/account/screens/voucher_screen.dart

import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoucherScreen extends StatelessWidget {
  final List<KhuyenMaiModel> voucherList;

  const VoucherScreen({super.key, required this.voucherList});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active   = voucherList.where((v) => v.ngayKetThuc.isAfter(now)).toList();
    final expired  = voucherList.where((v) => !v.ngayKetThuc.isAfter(now)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: voucherList.isEmpty
                ? _empty()
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionLabel('Đang áp dụng', AppColor.kCourtGreen),
                  const SizedBox(height: 10),
                  ...active.map((v) => _VoucherCard(voucher: v, expired: false)),
                ],
                if (expired.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionLabel('Đã hết hạn', Colors.grey),
                  const SizedBox(height: 10),
                  ...expired.map((v) => _VoucherCard(voucher: v, expired: true)),
                ],
              ],
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
                child: Text('Voucher của tôi',
                    style: TextStyle(
                      color: AppColor.kLineWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.kAccentYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${voucherList.length} voucher',
                    style: const TextStyle(
                      color: AppColor.kDeepGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, color: Colors.grey[300], size: 52),
          const SizedBox(height: 12),
          Text('Bạn chưa có voucher nào',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final KhuyenMaiModel voucher;
  final bool expired;

  const _VoucherCard({required this.voucher, required this.expired});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: expired ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: expired
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Left discount badge
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: expired
                  ? LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
                  : const LinearGradient(
                colors: [AppColor.kDeepGreen, AppColor.kCourtGreen],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-${(voucher.phanTramGiam * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text('GIẢM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),

          // Dash separator
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.tenKhuyenMai,
                    style: TextStyle(
                      color: expired
                          ? Colors.grey[500]
                          : AppColor.kTextDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 11,
                          color: expired
                              ? Colors.grey[400]
                              : Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'HSD: ${_fmtDate(voucher.ngayKetThuc)}',
                        style: TextStyle(
                          color: expired
                              ? Colors.grey[400]
                              : Colors.grey[500],
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (!expired)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: voucher.maKhuyenMai));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã sao chép mã voucher'),
                            backgroundColor: AppColor.kCourtGreen,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.kMintField,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 11,
                                color: AppColor.kCourtGreen),
                            const SizedBox(width: 4),
                            Text(voucher.maKhuyenMai,
                                style: const TextStyle(
                                  color: AppColor.kCourtGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                )),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Hết hạn',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}


// ─────────────────────────────────────────────────────────────────────────────
// Policy Screen
// ─────────────────────────────────────────────────────────────────────────────
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _PolicySection(
                  title: '1. Điều khoản sử dụng',
                  content:
                  'Bằng cách sử dụng ứng dụng SmashZone, bạn đồng ý tuân thủ các điều khoản và điều kiện được quy định dưới đây. SmashZone có quyền thay đổi điều khoản bất kỳ lúc nào mà không cần thông báo trước.',
                ),
                _PolicySection(
                  title: '2. Đặt sân & Thanh toán',
                  content:
                  'Người dùng phải thanh toán đúng hạn sau khi xác nhận đặt sân. Mọi giao dịch phải được thực hiện qua các kênh thanh toán chính thức của SmashZone. Chúng tôi không chịu trách nhiệm với các giao dịch ngoài hệ thống.',
                ),
                _PolicySection(
                  title: '3. Chính sách huỷ đặt sân',
                  content:
                  'Người dùng có thể huỷ đặt sân trước 2 giờ mà không mất phí. Huỷ trong vòng 2 giờ trước giờ chơi sẽ bị tính 50% phí huỷ. Không hoàn tiền cho trường hợp huỷ trong vòng 30 phút.',
                ),
                _PolicySection(
                  title: '4. Bảo mật thông tin',
                  content:
                  'SmashZone cam kết bảo vệ thông tin cá nhân của người dùng. Chúng tôi không chia sẻ dữ liệu với bên thứ ba trừ khi có sự đồng ý của bạn hoặc theo yêu cầu pháp lý. Dữ liệu được mã hóa và lưu trữ an toàn.',
                ),
                _PolicySection(
                  title: '5. Quyền và nghĩa vụ người dùng',
                  content:
                  'Người dùng có trách nhiệm cung cấp thông tin chính xác khi đăng ký. Nghiêm cấm sử dụng ứng dụng cho các mục đích bất hợp pháp. SmashZone có quyền khoá tài khoản vi phạm mà không cần thông báo.',
                ),
                _PolicySection(
                  title: '6. Giải quyết tranh chấp',
                  content:
                  'Mọi tranh chấp phát sinh sẽ được giải quyết thông qua thương lượng. Nếu không đạt được thỏa thuận, các bên có thể đưa ra Tòa án nhân dân có thẩm quyền tại TP. Hồ Chí Minh để giải quyết.',
                ),
                _PolicySection(
                  title: '7. Liên hệ',
                  content:
                  'Email hỗ trợ: support@smashzone.vn\nHotline: 1800 1234 (miễn phí)\nGiờ hỗ trợ: 7:00 – 22:00 hàng ngày',
                ),
              ],
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
              const Text('Chính sách & Bảo mật',
                  style: TextStyle(
                    color: AppColor.kLineWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColor.kCourtGreen,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              )),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.55,
              )),
        ],
      ),
    );
  }
}