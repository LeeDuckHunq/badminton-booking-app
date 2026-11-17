class UserModel {
  final String username;
  final String role;
  final String fullName;
  final String email;
  final String phoneNumber;

  UserModel({
    required this.username,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  /// Server không bao giờ trả về mật khẩu; các trường có thể null với tài khoản cũ.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'ROLE_USER',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}
