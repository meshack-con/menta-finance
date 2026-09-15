class LoginHistoryModel {
  final int id;
  final int userId;
  final String? username;
  final String? phoneNumber;
  final String? roles;
  final String? deviceUsed;
  final DateTime createdAt;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    this.username,
    this.phoneNumber,
    this.roles,
    this.deviceUsed,
    required this.createdAt,
  });

  factory LoginHistoryModel.fromJson(Map<String, dynamic> j) {
    return LoginHistoryModel(
      id: j['id'] as int,
      userId: j['user_id'] as int,
      username: j['username'],
      phoneNumber: j['phone_number'],
      roles: j['roles'],
      deviceUsed: j['device_used'],
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
