// lib/ui/chat/api/chat_api.dart
import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/ui/chat/models/chat_models.dart';
import 'package:flutter/foundation.dart';

class ChatApi {
  /// Lấy tất cả user (để hiện contact list)
  static Future<List<ChatUser>> getAllUsers() async {
    try {
      final res = await ApiClient.get('/user/get-all-user');
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

  /// Các cuộc trò chuyện của tài khoản đang đăng nhập (mới nhất trước).
  /// Trả về null nếu lỗi mạng.
  static Future<List<ChatRoom>?> getMyRooms() async {
    try {
      final res = await ApiClient.get('/chat/rooms');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ChatRoom.fromJson(e)).where((r) => r.maPhongChat.isNotEmpty).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Lấy hoặc tạo phòng chat giữa 2 user — trả về maPhongChat.
  /// Một trong hai username phải là tài khoản đang đăng nhập.
  static Future<String?> getOrCreateRoom({
    required String username1,
    required String username2,
  }) async {
    try {
      final res = await ApiClient.post('/chat/get-or-create-room', {
        'username1': username1,
        'username2': username2,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        // API trả về string roomId hoặc JSON object
        final body = res.body.trim();
        if (body.startsWith('"')) {
          return jsonDecode(body) as String;
        }
        try {
          final json = jsonDecode(body);
          return json['maPhongChat'] as String? ?? json['roomId'] as String? ?? body;
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
      final res = await ApiClient.get('/chat/messages/${Uri.encodeComponent(maPhongChat)}');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final msgs = data.map((e) => ChatMessage.fromJson(e)).toList();
        msgs.sort((a, b) => a.thoiGianGui.compareTo(b.thoiGianGui));
        return msgs;
      }
    } catch (e) {
      debugPrint('getMessages error: $e');
    }
    return [];
  }

  /// Gửi tin nhắn (server lấy người gửi từ JWT).
  static Future<bool> sendMessage({
    required String maPhongChat,
    required String usernameNguoiGui,
    required String noiDung,
  }) async {
    try {
      final res = await ApiClient.post('/chat/send-message', {
        'maPhongChat': maPhongChat,
        'noiDung': noiDung,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {}
    return false;
  }
}
