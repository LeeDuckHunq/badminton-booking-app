// lib/ui/account/screens/voucher_screen.dart
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/ui/claim_voucher/widgets/voucher_card.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// M18 – Voucher của tôi.
class VoucherScreen extends StatelessWidget {
  final List<KhuyenMaiModel> voucherList;

  const VoucherScreen({super.key, required this.voucherList});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = voucherList.where((v) => !v.ngayKetThuc.isBefore(now)).toList()..sort((a, b) => a.ngayKetThuc.compareTo(b.ngayKetThuc));
    final expired = voucherList.where((v) => v.ngayKetThuc.isBefore(now)).toList();

    Widget copyButton(KhuyenMaiModel v) => SzButton.small('Sao chép mã', icon: Icons.content_copy_rounded, kind: SzButtonKind.soft, onPressed: () {
          Clipboard.setData(ClipboardData(text: v.maKhuyenMai));
          showSzSnack(context, 'Đã sao chép mã ${v.maKhuyenMai}');
        });

    return Scaffold(
      appBar: SzTopBar(title: 'Voucher của tôi', subtitle: '${voucherList.length} voucher trong ví'),
      body: voucherList.isEmpty
          ? SzEmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'Bạn chưa có voucher nào',
              message: 'Nhận voucher miễn phí ở tab Khám phá để giảm giá khi đặt sân.',
              actionLabel: 'Quay lại',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Row(children: [
                    const Icon(Icons.tips_and_updates_outlined, color: AppColor.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Voucher được chọn ở bước thanh toán. Mỗi voucher dùng được một lần.', style: AppText.body())),
                  ]),
                ),
                const SizedBox(height: 16),
                if (active.isNotEmpty) ...[
                  _GroupLabel('Đang áp dụng', active.length),
                  for (final v in active) ...[VoucherTicket(voucher: v, action: copyButton(v)), const SizedBox(height: 12)],
                ],
                if (expired.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _GroupLabel('Đã hết hạn', expired.length),
                  for (final v in expired) ...[VoucherTicket(voucher: v, dimmed: true, action: const SizedBox.shrink()), const SizedBox(height: 12)],
                ],
              ],
            ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final int count;
  const _GroupLabel(this.text, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(children: [
        Text(text, style: AppText.headlineSm()),
        const SizedBox(width: 8),
        SzPill('$count'),
      ]),
    );
  }
}

/// M19 – Chính sách & Bảo mật.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  static const _sections = [
    (Icons.gavel_rounded, '1. Điều khoản sử dụng', 'Bằng cách sử dụng ứng dụng SmashZone, bạn đồng ý tuân thủ các điều khoản và điều kiện được quy định dưới đây. SmashZone có quyền thay đổi điều khoản bất kỳ lúc nào mà không cần thông báo trước.'),
    (Icons.payments_outlined, '2. Đặt sân & Thanh toán', 'Người dùng phải thanh toán đúng hạn sau khi xác nhận đặt sân. Mọi giao dịch phải được thực hiện qua các kênh thanh toán chính thức của SmashZone. Chúng tôi không chịu trách nhiệm với các giao dịch ngoài hệ thống.'),
    (Icons.event_busy_outlined, '3. Chính sách huỷ đặt sân', 'Người dùng có thể huỷ đặt sân trước 2 giờ mà không mất phí. Huỷ trong vòng 2 giờ trước giờ chơi sẽ bị tính 50% phí huỷ. Không hoàn tiền cho trường hợp huỷ trong vòng 30 phút.'),
    (Icons.lock_outline_rounded, '4. Bảo mật thông tin', 'SmashZone cam kết bảo vệ thông tin cá nhân của người dùng. Chúng tôi không chia sẻ dữ liệu với bên thứ ba trừ khi có sự đồng ý của bạn hoặc theo yêu cầu pháp lý. Dữ liệu được mã hóa và lưu trữ an toàn.'),
    (Icons.person_outline_rounded, '5. Quyền và nghĩa vụ người dùng', 'Người dùng có trách nhiệm cung cấp thông tin chính xác khi đăng ký. Nghiêm cấm sử dụng ứng dụng cho các mục đích bất hợp pháp. SmashZone có quyền khoá tài khoản vi phạm mà không cần thông báo.'),
    (Icons.balance_rounded, '6. Giải quyết tranh chấp', 'Mọi tranh chấp phát sinh sẽ được giải quyết thông qua thương lượng. Nếu không đạt được thỏa thuận, các bên có thể đưa ra Tòa án nhân dân có thẩm quyền tại TP. Hồ Chí Minh để giải quyết.'),
    (Icons.support_agent_rounded, '7. Liên hệ', 'Email hỗ trợ: support@smashzone.vn\nHotline: 1800 1234 (miễn phí)\nGiờ hỗ trợ: 07:00 – 22:00 hàng ngày'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SzTopBar(title: 'Chính sách & Bảo mật'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [AppColor.primaryDark, AppColor.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Điều khoản SmashZone', style: AppText.headlineMd(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Quy định sử dụng, thanh toán và bảo vệ dữ liệu của bạn', style: AppText.body(color: const Color(0xFFCFF5D6))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, content) in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SzCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: title.startsWith('1.'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(64, 0, 16, 16),
                    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColor.mint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: AppColor.primary)),
                    title: Text(title, style: AppText.headlineSm()),
                    iconColor: AppColor.primary,
                    collapsedIconColor: AppColor.textMuted,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(content, style: AppText.body(color: AppColor.textMuted).copyWith(height: 1.6))],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
