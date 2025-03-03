class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String countryCode;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.countryCode,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      countryCode: json['countryCode'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'countryCode': countryCode,
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? countryCode,
  }) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      countryCode: countryCode ?? this.countryCode,
      role: role,
      isActive: isActive,
    );
  }
}
