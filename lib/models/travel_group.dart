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

  // Méthode pour créer une copie d'un groupe avec des modifications
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

  // Méthode pour convertir l'objet en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members.map((member) => member.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Méthode pour créer un objet à partir d'un Map
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

  // Méthode pour créer une copie d'un membre avec des modifications
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

  // Méthode pour convertir l'objet en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  // Méthode pour créer un objet à partir d'un Map
  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
    );
  }
}