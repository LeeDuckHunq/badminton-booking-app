// lib/ui/chat/models/chat_models.dart

class ChatUser {
  final String username;
  final String fullName;
  final String role;

  const ChatUser({required this.username, required this.fullName, this.role = 'ROLE_USER'});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        username: json['username'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? 'ROLE_USER',
      );

  String get displayName => fullName.trim().isEmpty ? username : fullName;

  bool get isOwner => role == 'ROLE_OWNER';

  bool get isAdmin => role == 'ROLE_ADMIN';
}

/// Một cuộc trò chuyện của người dùng hiện tại.
class ChatRoom {
  final String maPhongChat;
  final ChatUser peer;
  final String? lastMessage;
  final DateTime? lastTime;

  const ChatRoom({required this.maPhongChat, required this.peer, this.lastMessage, this.lastTime});

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        maPhongChat: json['maPhongChat'] as String? ?? '',
        peer: ChatUser(
          username: json['peerUsername'] as String? ?? '',
          fullName: json['peerFullName'] as String? ?? '',
          role: json['peerRole'] as String? ?? 'ROLE_USER',
        ),
        lastMessage: json['tinNhanCuoi'] as String?,
        lastTime: DateTime.tryParse('${json['thoiGianTinNhanCuoi']}'),
      );
}

class ChatMessage {
  final String maTinNhan;
  final String maPhongChat;
  final String usernameNguoiGui;
  final String noiDung;
  final DateTime thoiGianGui;
  final bool pending;

  const ChatMessage({
    required this.maTinNhan,
    required this.maPhongChat,
    required this.usernameNguoiGui,
    required this.noiDung,
    required this.thoiGianGui,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      maTinNhan: json['maTinNhan']?.toString() ?? '',
      maPhongChat: json['maPhongChat']?.toString() ?? '',
      usernameNguoiGui: json['usernameNguoiGui']?.toString() ?? '',
      noiDung: json['noiDung']?.toString() ?? '',
      thoiGianGui: DateTime.tryParse('${json['thoiGianGui']}')?.toLocal() ?? DateTime.now(),
    );
  }
}
