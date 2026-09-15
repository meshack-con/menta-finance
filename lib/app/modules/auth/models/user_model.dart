class UserModel {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String roles;
  final String permissions;
  final int active;
  final bool isBlocked;

  UserModel({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.roles,
    required this.permissions,
    required this.active,
    required this.isBlocked,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      roles: json['roles'] as String? ?? '',
      permissions: json['permissions'] as String? ?? '',
      active: json['active'] as int? ?? 0,
      isBlocked: json['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'roles': roles,
        'permissions': permissions,
        'active': active,
        'is_blocked': isBlocked,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  List<String> get roleList => roles.split(',').where((r) => r.trim().isNotEmpty).toList();
}
