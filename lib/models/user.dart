class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String countryCode;
  final String? role;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      countryCode: json['countryCode'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'countryCode': countryCode,
      // Don't include id, email and role as they shouldn't be updated by the client
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
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      countryCode: countryCode ?? this.countryCode,
      role: role,
    );
  }
}
