class Message {
  final String text;
  String translation;
  final DateTime timestamp;
  final bool isUser;
  final String detectedLanguage;

  Message({
    required this.text,
    required this.translation,
    required this.timestamp,
    required this.isUser,
    this.detectedLanguage = 'en',
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'translation': translation,
        'timestamp': timestamp.toIso8601String(),
        'isUser': isUser,
        'detectedLanguage': detectedLanguage,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        translation: json['translation'],
        timestamp: DateTime.parse(json['timestamp']),
        isUser: json['isUser'],
        detectedLanguage: json['detectedLanguage'] ?? 'en',
      );
}
