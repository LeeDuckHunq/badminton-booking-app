// Chế độ xem trước từng màn hình để chụp ảnh / kiểm tra giao diện khi phát triển.
// Chỉ được biên dịch vào app khi build với `--dart-define=SZ_PREVIEW=true`;
// bản phát hành (không có cờ này) không chứa đoạn mã này.
//
// Dùng trên web: http://host/?preview=<màn>&...  ví dụ:
//   ?preview=home&tab=3            ?preview=schedule&venue=CS_123
//   ?preview=invoice&booking=PD_x  ?preview=chat&peer=hoanganh
//   ?preview=match&id=TR_x         ?preview=group&id=NH_x  ?preview=create-match
import 'package:application/api/chat_api.dart';
import 'package:application/api/cum_san_api.dart';
import 'package:application/api/hinh_anh_san_api.dart';
import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/model/san_model.dart';
import 'package:application/ui/account/screens/booking_history_screen.dart';
import 'package:application/ui/chat/screens/conversation_screen.dart';
import 'package:application/ui/community/create_match_screen.dart';
import 'package:application/ui/community/group_detail_screen.dart';
import 'package:application/ui/community/match_detail_screen.dart';
import 'package:application/ui/home/widgets/home_bottom_nav.dart';
import 'package:application/ui/invoice/models/invoice_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/screen/home_screen.dart';
import 'package:application/ui/screen/invoice_screen.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:application/ui/screen/register_screen.dart';
import 'package:application/ui/screen/search_screen.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kPreviewEnabled = bool.fromEnvironment('SZ_PREVIEW');

/// Trả về màn hình xem trước theo query `?preview=`, hoặc null nếu không bật.
Widget? previewHome() {
  if (!kPreviewEnabled) return null;
  final q = Uri.base.queryParameters;
  final name = q['preview'];
  if (name == null) return null;
  return switch (name) {
    'login' => const LoginScreen(),
    'register' => const RegisterScreen(),
    'match' => MatchDetailScreen(matchId: q['id']!),
    'group' => GroupDetailScreen(groupId: q['id']!),
    'create-match' => CreateMatchScreen(groupId: q['group']),
    'home' => HomeScreen(initialTab: HomeNavTab.values[int.tryParse(q['tab'] ?? '0') ?? 0]),
    _ => _AsyncPreview(name: name, params: q),
  };
}

class _AsyncPreview extends StatelessWidget {
  final String name;
  final Map<String, String> params;
  const _AsyncPreview({required this.name, required this.params});

  Future<Widget> _build() async {
    switch (name) {
      case 'schedule':
        final venue = await CumSanApi.getCumSanInfo(params['venue']!);
        return BookingScheduleScreen(cumSan: venue!);
      case 'search':
        final courts = await CumSanApi.getCumSan(100) ?? [];
        final images = await HinhAnhSanApi.getAllHinhAnhSan();
        return SearchScreen(courtList: courts, courtImage: images);
      case 'invoice':
        final prefs = await SharedPreferences.getInstance();
        final bookings = await PhieuDatSanApi.getPhieuDatSanTheoUser(prefs.getString('username')!);
        final p = bookings.firstWhere((b) => b.maPhieuDat == params['booking']);
        final san = await SanApi.getSanInfo(p.maSan);
        final venue = await CumSanApi.getCumSanInfo(san!.maCumSan);
        return InvoiceScreen(
          maPhieuDat: p.maPhieuDat,
          booking: InvoiceBookingInfo(maPhieuDat: p.maPhieuDat, tenCumSan: venue!.tenCumSan, tenSan: san.tenSan, diaChi: venue.diaChi, batDau: p.batDau, ketThuc: p.ketThuc, tongTien: p.tongTien, giaGio: san.gia),
        );
      case 'history':
        final prefs = await SharedPreferences.getInstance();
        final bookings = await PhieuDatSanApi.getPhieuDatSanTheoUser(prefs.getString('username')!);
        final venues = await CumSanApi.getCumSan(100) ?? [];
        final sanMap = <String, SanModel>{};
        for (final v in venues) {
          for (final san in await SanApi.getSanTheoCumSan(v.maCumSan)) {
            sanMap[san.maSan] = san;
          }
        }
        return BookingHistoryScreen(
          phieuList: bookings,
          sanMap: sanMap,
          cumSanMap: {for (final v in venues) v.maCumSan: v},
          images: await HinhAnhSanApi.getAllHinhAnhSan(),
        );
      case 'chat':
        final prefs = await SharedPreferences.getInstance();
        final users = await ChatApi.getAllUsers();
        final peer = users.firstWhere((u) => u.username == params['peer']);
        return ConversationScreen(currentUsername: prefs.getString('username')!, peer: peer);
      default:
        return Scaffold(body: Center(child: Text('Không có màn xem trước "$name"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _build(),
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(body: Center(child: Text('Lỗi xem trước: ${snap.error}')));
        if (!snap.hasData) return const Scaffold(body: SzLoading());
        return snap.data!;
      },
    );
  }
}
