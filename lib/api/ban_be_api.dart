import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:application/ui/chat/models/chat_models.dart';

/// Một người trong danh sách bạn bè / kết quả tìm kiếm.
class Person {
  final String username;
  final String fullName;
  final String role;

  /// KHONG, DA_GUI (mình đã mời), DUOC_MOI (người kia mời mình), BAN_BE.
  final String quanHe;

  /// Hồ sơ công khai: có mở được cuộc trò chuyện không.
  final bool coTheNhan;

  const Person({required this.username, required this.fullName, this.role = 'ROLE_USER', this.quanHe = 'KHONG', this.coTheNhan = false});

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        username: j['username'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        role: j['role'] as String? ?? 'ROLE_USER',
        quanHe: j['quanHe'] as String? ?? 'KHONG',
        coTheNhan: j['coTheNhan'] == true,
      );

  Person withRelation(String q) => Person(username: username, fullName: fullName, role: role, quanHe: q, coTheNhan: coTheNhan || q == 'BAN_BE');

  String get displayName => fullName.trim().isEmpty ? username : fullName;
  ChatUser get chatUser => ChatUser(username: username, fullName: fullName, role: role);
}

class FriendsOverview {
  final List<Person> friends;
  final List<Person> incoming;
  final List<Person> outgoing;
  const FriendsOverview(this.friends, this.incoming, this.outgoing);
}

class BanBeApi {
  static List<Person> _list(dynamic data) => ((data as List?) ?? []).map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();

  static Future<FriendsOverview?> overview() async {
    try {
      final res = await ApiClient.get('/ban-be');
      if (res.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      // Quan hệ theo nhóm danh sách (phòng khi máy chủ không gửi kèm).
      List<Person> as(String key, String q) => [for (final p in _list(d[key])) p.quanHe == 'KHONG' ? p.withRelation(q) : p];
      return FriendsOverview(as('banBe', 'BAN_BE'), as('loiMoiDen', 'DUOC_MOI'), as('loiMoiDi', 'DA_GUI'));
    } catch (_) {
      return null;
    }
  }

  static Future<List<Person>> search(String q) async {
    try {
      final res = await ApiClient.get('/ban-be/tim?q=${Uri.encodeQueryComponent(q)}');
      if (res.statusCode != 200) return [];
      return _list(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      return [];
    }
  }

  /// Hồ sơ công khai (null nếu không tìm thấy / lỗi mạng).
  static Future<Person?> profile(String username) async {
    try {
      final res = await ApiClient.get('/ban-be/ho-so/${Uri.encodeComponent(username)}');
      if (res.statusCode != 200) return null;
      return Person.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Trả về quan hệ mới, hoặc ném lỗi kèm thông báo.
  static Future<String> invite(String username) => _relation(() => ApiClient.post('/ban-be/loi-moi', {'username': username}));

  static Future<String> accept(String username) => _relation(() => ApiClient.post('/ban-be/${Uri.encodeComponent(username)}/dong-y', null));

  static Future<void> remove(String username) async {
    final res = await ApiClient.delete('/ban-be/${Uri.encodeComponent(username)}');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res) ?? 'Không thực hiện được');
  }

  static Future<String> _relation(Future<dynamic> Function() call) async {
    final res = await call();
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res) ?? 'Không thực hiện được');
    final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return d['quanHe'] as String? ?? 'KHONG';
  }
}
