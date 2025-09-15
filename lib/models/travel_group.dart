import 'package:uuid/uuid.dart';

class TravelGroup {
  final String id;
  final String name;
  final List<GroupMember> members;
  final DateTime createdAt;

  TravelGroup({
    String? id,
    required this.name,
    required this.members,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // Method to create a copy of a group with modifications
  TravelGroup copyWith({
    String? id,
    String? name,
    List<GroupMember>? members,
    DateTime? createdAt,
  }) {
    return TravelGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert the object to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members.map((member) => member.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create an object from a Map
  factory TravelGroup.fromMap(Map<String, dynamic> map) {
    return TravelGroup(
      id: map['id'],
      name: map['name'],
      members: (map['members'] as List)
          .map((memberMap) => GroupMember.fromMap(memberMap))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}

class GroupMember {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;

  GroupMember({
    String? id,
    required this.name,
    this.email,
    this.photoUrl,
  }) : id = id ?? const Uuid().v4();

  // Method to create a copy of a member with modifications
  GroupMember copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  // Convert the object to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  // Create an object from a Map
  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
    );
  }
}