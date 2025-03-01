import 'dart:convert';
import 'package:flutter/material.dart';
import 'message.dart';

class Discussion {
  final String id;
  List<Message> messages;
  String category;
  final DateTime createdAt;
  bool isFavorite;

  Discussion({
    required this.id,
    required this.messages,
    required this.category,
    required this.createdAt,
    this.isFavorite = false,
  });

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  bool isExpired() {
    if (isFavorite) return false;
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours >= 24;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messages': messages.map((m) => m.toJson()).toList(),
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory Discussion.fromJson(Map<String, dynamic> json) => Discussion(
        id: json['id'],
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList(),
        category: json['category'],
        createdAt: DateTime.parse(json['createdAt']),
        isFavorite: json['isFavorite'] ?? false,
      );

  String exportToText() {
    final buffer = StringBuffer();
    buffer.writeln('Discussion in $category');
    buffer.writeln('Created at: ${createdAt.toLocal()}');
    buffer.writeln('');
    
    for (final message in messages) {
      buffer.writeln('${message.isUser ? "You" : "Assistant"} (${message.detectedLanguage}):');
      buffer.writeln(message.text);
      buffer.writeln('Translation:');
      buffer.writeln(message.translation);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  String exportToJson() {
    return jsonEncode(toJson());
  }
}
