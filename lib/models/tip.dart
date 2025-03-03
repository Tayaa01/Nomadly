

class Tip {
  final String category;
  final String content;
  
  Tip({
    required this.category,
    required this.content,
  });
  
  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      category: json['category'] ?? '',
      content: json['content'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'content': content,
    };
  }
}

class TipsService {
  static Future<List<String>> getAvailableCountries() async {
    // Placeholder implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      'Japan',
      'France',
      'Italy',
      'United States',
      'United Kingdom',
      'Spain',
      'Germany',
      'China',
      'Australia',
      'Canada',
      'Brazil',
      'Mexico',
      'South Korea',
      'India',
      'Egypt',
      'Morocco',
      'Thailand',
    ];
  }

  static Future<List<String>> getCategoriesForCountry(String country) async {
    // Placeholder implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      'Dining',
      'Social Etiquette',
      'Business',
      'Religious Customs',
      'Gifts',
      'Language',
      'Social Interactions',
      'Gender Considerations',
      'Numbers',
    ];
  }

  static Future<List<Tip>> getTipsByCountryAndCategory(
    String country,
    String category,
  ) async {
    // Placeholder implementation
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Some sample tips for demonstration
    final Map<String, List<String>> sampleTips = {
      'Dining': [
        'In $country, it\'s customary to wait for everyone to be served before starting to eat.',
        'When dining in $country, avoid resting your elbows on the table.',
        'Tipping in $country is typically around 10-15% in restaurants.',
        'It\'s polite to finish all food on your plate in $country.',
      ],
      'Social Etiquette': [
        'In $country, always remove your shoes before entering someone\'s home.',
        'Public displays of affection are generally frowned upon in $country.',
        'Maintaining eye contact while speaking is considered respectful in $country.',
        'In $country, it\'s customary to bring a small gift when visiting someone\'s home.',
      ],
      'Business': [
        'Business cards should be exchanged with both hands in $country.',
        'Punctuality is highly valued in $country business meetings.',
        'Dress conservatively for business meetings in $country.',
        'In $country, decisions are typically made by consensus rather than by individuals.',
      ],
    };
    
    final tips = sampleTips[category] ?? 
      ['No specific tips available for $category in $country'];
    
    return tips.map((content) => Tip(
      category: category,
      content: content,
    )).toList();
  }
}
