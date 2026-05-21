// lib/ui/chat/models/chat_models.dart

class ChatUser {
  final String username;
  final String fullName;

  const ChatUser({required this.username, required this.fullName});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
    username: json['username'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
  );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class ChatMessage {
  final String maTinNhan;
  final String maPhongChat;
  final String usernameNguoiGui;
  final String noiDung;
  final DateTime thoiGianGui;

  const ChatMessage({
    required this.maTinNhan,
    required this.maPhongChat,
    required this.usernameNguoiGui,
    required this.noiDung,
    required this.thoiGianGui,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;

    try {
      parsedTime = DateTime.parse(
        '${json['thoiGianGui']}Z',
      ).toLocal();
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return ChatMessage(
      maTinNhan: json['maTinNhan']?.toString() ?? '',
      maPhongChat: json['maPhongChat']?.toString() ?? '',
      usernameNguoiGui:
      json['usernameNguoiGui']?.toString() ?? '',
      noiDung: json['noiDung']?.toString() ?? '',
      thoiGianGui: parsedTime,
    );
  }
}