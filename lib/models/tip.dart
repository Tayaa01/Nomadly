class Tip {
  final String country;
  final String category;
  final String content;

  Tip({
    required this.country,
    required this.category,
    required this.content,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      country: json['country'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'category': category,
      'content': content,
    };
  }
}
