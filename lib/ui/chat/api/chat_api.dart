// lib/ui/chat/api/chat_api.dart

import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:http/http.dart' as http;

class ChatApi {
  static String get _base => ServerAddress().address;

  /// Lấy tất cả user (để hiện contact list)
  static Future<List<ChatUser>> getAllUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/user/get-all-user'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => ChatUser.fromJson(e))
            .where((u) => u.username.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Lấy hoặc tạo phòng chat giữa 2 user — trả về maPhongChat
  static Future<String?> getOrCreateRoom({
    required String username1,
    required String username2,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/chat/get-or-create-room'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username1': username1,
          'username2': username2,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        // API trả về string roomId hoặc JSON object
        final body = res.body.trim();
        if (body.startsWith('"')) {
          return jsonDecode(body) as String;
        }
        try {
          final json = jsonDecode(body);
          return json['maPhongChat'] as String? ??
              json['roomId'] as String? ??
              body;
        } catch (_) {
          return body;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Lấy tin nhắn của phòng
  static Future<List<ChatMessage>> getMessages(String maPhongChat) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/chat/messages/$maPhongChat'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final msgs = data.map((e) => ChatMessage.fromJson(e)).toList();
        msgs.sort((a, b) => a.thoiGianGui.compareTo(b.thoiGianGui));
        return msgs;
      }
    } catch (_) {}
    return [];
  }

  /// Gửi tin nhắn
  static Future<bool> sendMessage({
    required String maPhongChat,
    required String usernameNguoiGui,
    required String noiDung,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/chat/send-message'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'maPhongChat': maPhongChat,
          'usernameNguoiGui': usernameNguoiGui,
          'noiDung': noiDung,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {}
    return false;
  }
}