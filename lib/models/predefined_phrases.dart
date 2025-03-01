class PredefinedPhrases {
  static Map<String, List<Map<String, String>>> phrasesByCategory = {
    'General': [
      {'text': 'Hello', 'translation': 'Bonjour'},
      {'text': 'Thank you', 'translation': 'Merci'},
      {'text': 'You\'re welcome', 'translation': 'De rien'},
      {'text': 'Goodbye', 'translation': 'Au revoir'},
    ],
    'Restaurant': [
      {'text': 'The menu please', 'translation': 'Le menu s\'il vous plaît'},
      {'text': 'The bill please', 'translation': 'L\'addition s\'il vous plaît'},
      {'text': 'A table for two', 'translation': 'Une table pour deux'},
    ],
    'Hotel': [
      {'text': 'I have a reservation', 'translation': 'J\'ai une réservation'},
      {'text': 'Where is my room?', 'translation': 'Où est ma chambre?'},
      {'text': 'The key please', 'translation': 'La clé s\'il vous plaît'},
    ],
    'Transport': [
      {'text': 'Where is the station?', 'translation': 'Où est la gare?'},
      {'text': 'How much is the ticket?', 'translation': 'Combien coûte le billet?'},
      {'text': 'What time is the next train?', 'translation': 'À quelle heure est le prochain train?'},
    ],
    'Emergency': [
      {'text': 'I need help', 'translation': 'J\'ai besoin d\'aide'},
      {'text': 'Call the police', 'translation': 'Appelez la police'},
      {'text': 'Where is the hospital?', 'translation': 'Où est l\'hôpital?'},
    ],
    'Shopping': [
      {'text': 'How much is it?', 'translation': 'Combien ça coûte?'},
      {'text': 'Do you accept credit cards?', 'translation': 'Acceptez-vous les cartes de crédit?'},
      {'text': 'Can I try it on?', 'translation': 'Puis-je l\'essayer?'},
    ],
    'Other': [
      {'text': 'Can you help me?', 'translation': 'Pouvez-vous m\'aider?'},
      {'text': 'I don\'t understand', 'translation': 'Je ne comprends pas'},
      {'text': 'Could you repeat that?', 'translation': 'Pourriez-vous répéter?'},
      {'text': 'Thank you very much', 'translation': 'Merci beaucoup'},
    ],
  };

  static Map<String, String> categoryIcons = {
    'General': '🌐',
    'Restaurant': '🍽️',
    'Hotel': '🏨',
    'Transport': '🚆',
    'Emergency': '🚨',
    'Shopping': '🛍️',
    'Other': '📝',
  };

  static void addCustomCategory(String category, {String icon = '📝'}) {
    if (!phrasesByCategory.containsKey(category)) {
      phrasesByCategory[category] = [];
      categoryIcons[category] = icon;
    }
  }

  static void addPhraseToCategory(String category, String text, String translation) {
    if (!phrasesByCategory.containsKey(category)) {
      addCustomCategory(category);
    }
    phrasesByCategory[category]!.add({
      'text': text,
      'translation': translation,
    });
  }
}
