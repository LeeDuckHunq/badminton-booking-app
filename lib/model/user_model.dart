class UserModel {
  final String username;
  final String password;
  final String role;
  final String fullName;
  final String email;
  final String phoneNumber;

  UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      password: json['password'],
      role: json['role'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
    );
  }
}