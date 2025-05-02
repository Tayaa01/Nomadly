class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String countryCode;
  final String currency; // Add currency field
  final String? role;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.currency, // Make currency required
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      countryCode: json['countryCode'] ?? '',
      currency: json['currency'] ?? '', // Read currency from JSON
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'countryCode': countryCode,
      'currency': currency, // Include currency in update payload
      // Don't include id, email and role as they shouldn't be updated by the client
    };
  }

  // NEW: toJsonForStorage for saving complete user data locally
  Map<String, dynamic> toJsonForStorage() {
    return {
      '_id': id, // Use '_id' consistent with fromJson
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'countryCode': countryCode,
      'currency': currency, // Include currency for storage
      'role': role,
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? countryCode,
    String? currency, // Add currency parameter
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      countryCode: countryCode ?? this.countryCode,
      currency: currency ?? this.currency, // Use provided or existing currency
      role: role,
    );
  }
}
