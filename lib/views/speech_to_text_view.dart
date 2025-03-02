import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../models/discussion.dart';
import '../models/message.dart';
import '../models/predefined_phrases.dart';
import '../services/translation_cache_service.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_bottom_nav.dart';

class SpeechToTextView extends StatefulWidget {
  const SpeechToTextView({super.key});

  @override
  _SpeechToTextViewState createState() => _SpeechToTextViewState();
}

class _SpeechToTextViewState extends State<SpeechToTextView>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late TtsService _ttsService;
  late SharedPreferences _prefs;
  bool _isListening = false;
  String _text = 'Say something';
  String _translatedText = '';
  bool _isTranslating = false;
  double _confidence = 1.0;
  late AnimationController _animationController;
  Timer? _debounce;
  bool _isRequestPending = false;
  List<Discussion> _discussions = [];
  Discussion? _currentDiscussion;
  final TextEditingController _messageController = TextEditingController();

  String _selectedSourceLanguage = 'en';
  String _selectedTargetLanguage = 'fr';
  String _selectedCategory = 'All';
  bool _isOfflineMode = false;
  final bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'af', 'name': 'Afrikaans'},
    {'code': 'sq', 'name': 'Albanian'},
    {'code': 'am', 'name': 'Amharic'},
    {'code': 'hy', 'name': 'Armenian'},
    {'code': 'az', 'name': 'Azerbaijani'},
    {'code': 'eu', 'name': 'Basque'},
    {'code': 'be', 'name': 'Belarusian'},
    {'code': 'bn', 'name': 'Bengali'},
    {'code': 'bs', 'name': 'Bosnian'},
    {'code': 'bg', 'name': 'Bulgarian'},
    {'code': 'ca', 'name': 'Catalan'},
    {'code': 'ceb', 'name': 'Cebuano'},
    {'code': 'ny', 'name': 'Chichewa'},
    {'code': 'co', 'name': 'Corsican'},
    {'code': 'hr', 'name': 'Croatian'},
    {'code': 'cs', 'name': 'Czech'},
    {'code': 'da', 'name': 'Danish'},
    {'code': 'nl', 'name': 'Dutch'},
    {'code': 'eo', 'name': 'Esperanto'},
    {'code': 'et', 'name': 'Estonian'},
    {'code': 'tl', 'name': 'Filipino'},
    {'code': 'fi', 'name': 'Finnish'},
    {'code': 'fy', 'name': 'Frisian'},
    {'code': 'gl', 'name': 'Galician'},
    {'code': 'ka', 'name': 'Georgian'},
    {'code': 'el', 'name': 'Greek'},
    {'code': 'gu', 'name': 'Gujarati'},
    {'code': 'ht', 'name': 'Haitian Creole'},
    {'code': 'ha', 'name': 'Hausa'},
    {'code': 'haw', 'name': 'Hawaiian'},
    {'code': 'iw', 'name': 'Hebrew'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'hmn', 'name': 'Hmong'},
    {'code': 'hu', 'name': 'Hungarian'},
    {'code': 'is', 'name': 'Icelandic'},
    {'code': 'ig', 'name': 'Igbo'},
    {'code': 'id', 'name': 'Indonesian'},
    {'code': 'ga', 'name': 'Irish'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'jw', 'name': 'Javanese'},
    {'code': 'kn', 'name': 'Kannada'},
    {'code': 'kk', 'name': 'Kazakh'},
    {'code': 'km', 'name': 'Khmer'},
    {'code': 'rw', 'name': 'Kinyarwanda'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ku', 'name': 'Kurdish (Kurmanji)'},
    {'code': 'ky', 'name': 'Kyrgyz'},
    {'code': 'lo', 'name': 'Lao'},
    {'code': 'la', 'name': 'Latin'},
    {'code': 'lv', 'name': 'Latvian'},
    {'code': 'lt', 'name': 'Lithuanian'},
    {'code': 'lb', 'name': 'Luxembourgish'},
    {'code': 'mk', 'name': 'Macedonian'},
    {'code': 'mg', 'name': 'Malagasy'},
    {'code': 'ms', 'name': 'Malay'},
    {'code': 'ml', 'name': 'Malayalam'},
    {'code': 'mt', 'name': 'Maltese'},
    {'code': 'mi', 'name': 'Maori'},
    {'code': 'mr', 'name': 'Marathi'},
    {'code': 'mn', 'name': 'Mongolian'},
    {'code': 'my', 'name': 'Myanmar (Burmese)'},
    {'code': 'ne', 'name': 'Nepali'},
    {'code': 'no', 'name': 'Norwegian'},
    {'code': 'or', 'name': 'Odia (Oriya)'},
    {'code': 'ps', 'name': 'Pashto'},
    {'code': 'fa', 'name': 'Persian'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'pa', 'name': 'Punjabi'},
    {'code': 'ro', 'name': 'Romanian'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'sm', 'name': 'Samoan'},
    {'code': 'gd', 'name': 'Scots Gaelic'},
    {'code': 'sr', 'name': 'Serbian'},
    {'code': 'st', 'name': 'Sesotho'},
    {'code': 'sn', 'name': 'Shona'},
    {'code': 'sd', 'name': 'Sindhi'},
    {'code': 'si', 'name': 'Sinhala'},
    {'code': 'sk', 'name': 'Slovak'},
    {'code': 'sl', 'name': 'Slovenian'},
    {'code': 'so', 'name': 'Somali'},
    {'code': 'su', 'name': 'Sundanese'},
    {'code': 'sw', 'name': 'Swahili'},
    {'code': 'sv', 'name': 'Swedish'},
    {'code': 'tg', 'name': 'Tajik'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'tt', 'name': 'Tatar'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'tk', 'name': 'Turkmen'},
    {'code': 'uk', 'name': 'Ukrainian'},
    {'code': 'ur', 'name': 'Urdu'},
    {'code': 'ug', 'name': 'Uyghur'},
    {'code': 'uz', 'name': 'Uzbek'},
    {'code': 'vi', 'name': 'Vietnamese'},
    {'code': 'cy', 'name': 'Welsh'},
    {'code': 'xh', 'name': 'Xhosa'},
    {'code': 'yi', 'name': 'Yiddish'},
    {'code': 'yo', 'name': 'Yoruba'},
    {'code': 'zu', 'name': 'Zulu'},
  ];

  final List<String> _supportedTtsLanguages = [
    'en', 'fr', 'es', 'de', 'it', 'zh', 'ja', 'ko', 'ru', 'pt',
    // Add other supported languages here
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _ttsService = TtsService();
    _initializePrefs();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Ajouter un timer pour nettoyer les discussions toutes les heures
    Timer.periodic(Duration(hours: 1), (_) => _cleanupOldDiscussions());
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadDiscussions();
  }

  void _loadDiscussions() {
    final discussionsJson = _prefs.getStringList('discussions') ?? [];
    _discussions =
        discussionsJson
            .map((json) => Discussion.fromJson(jsonDecode(json)))
            .toList();

    _cleanupOldDiscussions();
  }

  void _cleanupOldDiscussions() {
    final now = DateTime.now();
    bool hasRemovedDiscussions = false;

    _discussions.removeWhere((discussion) {
      if (discussion.isFavorite) return false; // Ne pas supprimer les favoris
      final isOld = discussion.isExpired();
      if (isOld) hasRemovedDiscussions = true;
      return isOld;
    });

    if (hasRemovedDiscussions) {
      _saveDiscussions();
      setState(() {});
    }
  }

  void _saveDiscussions() {
    final discussionsJson =
        _discussions
            .map((discussion) => jsonEncode(discussion.toJson()))
            .toList();
    _prefs.setStringList('discussions', discussionsJson);
  }

  void _createNewDiscussion() {
    _showCategorySelector(createNew: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounce?.cancel();
    _ttsService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _translateText() async {
    if (_text.isEmpty || _text == 'Say something' || _isRequestPending) return;

    setState(() {
      _isTranslating = true;
      _isRequestPending = true;
    });

    try {
      String translation;

      // Check cache in offline mode
      if (_isOfflineMode) {
        translation =
            await TranslationCacheService.getCachedTranslation(
              _text,
              _selectedSourceLanguage,
              _selectedTargetLanguage,
            ) ??
            'No offline translation available';
      } else {
        // Online translation
        final response = await _performOnlineTranslation();
        translation = response['translation'] ?? 'Translation failed';

        // Cache the translation
        await TranslationCacheService.cacheTranslation(
          _text,
          translation,
          _selectedSourceLanguage,
          _selectedTargetLanguage,
        );
      }

      setState(() {
        _translatedText = translation;
        if (_currentDiscussion != null) {
          _currentDiscussion!.messages.add(
            Message(
              text: _text,
              translation: _translatedText,
              timestamp: DateTime.now(),
              isUser: true,
              detectedLanguage: _selectedSourceLanguage,
            ),
          );
          _saveDiscussions();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translation error: $e')));
    } finally {
      setState(() {
        _isTranslating = false;
        _isRequestPending = false;
      });
    }
  }

  Future<void> _speak(String text, String language) async {
    print('Trying to speak: $text in language: $language');
    try {
      await _ttsService.speak(text, language);
    } catch (e) {
      print('Error in _speak: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  void _showLanguageSelector(bool isSource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ListView.builder(
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              final bool isTtsSupported = _supportedTtsLanguages.contains(
                language['code'],
              );
              return ListTile(
                title: Row(
                  children: [
                    Text(
                      language['name']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    if (!isTtsSupported)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          '(Translation only)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (isSource) {
                      _selectedSourceLanguage = language['code']!;
                    } else {
                      _selectedTargetLanguage = language['code']!;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done') {
            setState(() => _isListening = false);
            _animationController.stop();
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _text = ''; // Clear previous text
        });
        _animationController.repeat(reverse: true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              print('Recognized text: $_text');
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            });

            // Only start translation when speech recognition is done
            if (val.finalResult) {
              if (_text.isNotEmpty && _text != 'Say something') {
                _translateText();
              }
              setState(() => _isListening = false);
              _animationController.stop();
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _animationController.stop();
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading:
            _currentDiscussion == null
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => setState(() => _currentDiscussion = null),
                ),
        title:
            _isSearching
                ? _buildSearchField()
                : Text(
                  _currentDiscussion == null
                      ? 'Translate'
                      : _currentDiscussion!.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        actions: _buildAppBarActions(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
          ),
        ),
        child:
            _currentDiscussion == null
                ? _buildDiscussionsListView()
                : _buildDiscussionView(),
      ),
      floatingActionButton:
          _currentDiscussion == null
              ? FloatingActionButton.extended(
                onPressed: _createNewDiscussion,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'New Discussion',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF4CD964),
              )
              : null,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            // If not current tab
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/tips');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/currency-converter');
            }
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search discussions...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_currentDiscussion == null) {
      return [
        IconButton(
          icon: Icon(_isOfflineMode ? Icons.cloud_off : Icons.cloud),
          color: Colors.white,
          onPressed: () => setState(() => _isOfflineMode = !_isOfflineMode),
        ),
      ];
    }
    return [
      IconButton(
        icon: const Icon(Icons.language, color: Colors.white),
        onPressed: () => _showLanguageSelector(true),
        tooltip: 'Source Language',
      ),
      IconButton(
        icon: const Icon(Icons.translate, color: Colors.white),
        onPressed: () => _showLanguageSelector(false),
        tooltip: 'Target Language',
      ),
      IconButton(
        icon: const Icon(Icons.category, color: Colors.white),
        onPressed: _showCategorySelector,
      ),
    ];
  }

  Widget _buildDiscussionsListView() {
    final filteredDiscussions =
        _discussions.where((discussion) {
          if (_searchQuery.isEmpty) {
            return _selectedCategory == 'All' ||
                discussion.category == _selectedCategory;
          }

          final query = _searchQuery.toLowerCase();
          final matchesCategory =
              _selectedCategory == 'All' ||
              discussion.category == _selectedCategory;
          final matchesSearch = discussion.messages.any(
            (message) =>
                message.text.toLowerCase().contains(query) ||
                message.translation.toLowerCase().contains(query),
          );

          return matchesCategory && matchesSearch;
        }).toList();

    return Column(
      children: [
        _buildCategoryFilter(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[300], size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Discussions are automatically deleted after 24 hours',
                  style: TextStyle(color: Colors.blue[300], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (filteredDiscussions.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _selectedCategory == 'All'
                    ? 'No discussions yet'
                    : 'No discussions in this category',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredDiscussions.length,
              itemBuilder: (context, index) {
                final discussion = filteredDiscussions[index];
                return _buildDiscussionListItem(discussion);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children:
                [
                    'All',
                    ...PredefinedPhrases.phrasesByCategory.keys,
                  ].map((category) => _buildCategoryChip(category)).toList()
                  ..add(
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: ActionChip(
                        avatar: Icon(Icons.add, color: Colors.white, size: 18),
                        label: Text('New category'),
                        onPressed: _showAddCategoryDialog,
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Text(
          PredefinedPhrases.categoryIcons[category] ?? '📝',
          style: const TextStyle(fontSize: 14),
        ),
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : 'All');
        },
        backgroundColor: const Color(0xFF333333),
        selectedColor: const Color(0xFF4CD964),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDiscussionView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600; // Considérer comme web si largeur > 600px

    return Column(
      children: [
        _buildPredefinedPhrases(),
        Expanded(
          child: Container(
            constraints:
                isWeb
                    ? BoxConstraints(
                      maxWidth: 800,
                    ) // Limiter la largeur sur web
                    : null,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _currentDiscussion!.messages.length,
              itemBuilder: (context, index) {
                final message = _currentDiscussion!.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ),
        Container(
          constraints:
              isWeb
                  ? BoxConstraints(maxWidth: 800) // Limiter la largeur sur web
                  : null,
          child: _buildInputArea(),
        ),
      ],
    );
  }

  Widget _buildPredefinedPhrases() {
    final phrases =
        PredefinedPhrases.phrasesByCategory[_currentDiscussion!.category] ?? [];
    if (phrases.isEmpty) return SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(phrase['text']!),
              onPressed: () => _onPredefinedPhraseSelected(phrase),
              backgroundColor: Colors.grey[800],
              labelStyle: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? const Color(0xFF4CD964)
                  : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    message.translation,
                    style: TextStyle(
                      color:
                          message.isUser
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_supportedTtsLanguages.contains(
                  message.isUser
                      ? _selectedTargetLanguage
                      : message.detectedLanguage,
                ))
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color:
                          message.isUser
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed:
                        () => _speak(
                          message.isUser ? message.translation : message.text,
                          message.isUser
                              ? _selectedTargetLanguage
                              : message.detectedLanguage,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onSubmitted: _onTextSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color:
                          _isListening ? const Color(0xFF4CD964) : Colors.grey,
                    ),
                    onPressed: _listen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4CD964),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: () => _onTextSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelector({bool createNew = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ListView.builder(
            itemCount: PredefinedPhrases.phrasesByCategory.length,
            itemBuilder: (context, index) {
              final category = PredefinedPhrases.phrasesByCategory.keys
                  .elementAt(index);
              return ListTile(
                title: Text(category, style: TextStyle(color: Colors.white)),
                onTap: () {
                  if (createNew) {
                    final newDiscussion = Discussion(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      messages: [],
                      createdAt: DateTime.now(),
                      category: category,
                    );
                    setState(() {
                      _discussions.add(newDiscussion);
                      _currentDiscussion = newDiscussion;
                    });
                    _saveDiscussions();
                  } else {
                    setState(() {
                      _currentDiscussion!.category = category;
                    });
                    _saveDiscussions();
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
    );
  }

  void _onPredefinedPhraseSelected(Map<String, String> phrase) {
    setState(() {
      _text = phrase['text']!;
      _translateText();
    });
  }

  void _onTextSubmitted(String text) {
    setState(() {
      _text = text;
      _translateText();
      _messageController.clear();
    });
  }

  Future<Map<String, String>> _performOnlineTranslation() async {
    final String url =
        'https://lingva.ml/api/v1/$_selectedSourceLanguage/$_selectedTargetLanguage/${Uri.encodeComponent(_text)}';

    print('Sending translation request with text: $_text');
    print(
      'Source language: $_selectedSourceLanguage, Target language: $_selectedTargetLanguage',
    );
    final response = await http.get(Uri.parse(url));

    print('Received response with status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'translation': data['translation'] ?? 'Translation failed'};
    } else {
      final errorMessage =
          jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception(
        'Failed to translate: ${response.statusCode}, Message: $errorMessage',
      );
    }
  }

  Widget _buildDiscussionListItem(Discussion discussion) {
    final lastMessage =
        discussion.messages.isNotEmpty ? discussion.messages.last : null;

    final now = DateTime.now();
    final hoursLeft =
        discussion.isFavorite
            ? null
            : 24 - now.difference(discussion.createdAt).inHours;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            PredefinedPhrases.categoryIcons[discussion.category] ?? '📝',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          lastMessage?.text ?? 'Empty discussion',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CD964),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discussion.category,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hoursLeft != null)
                  Text(
                    '${hoursLeft}h left',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                lastMessage.translation,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                discussion.isFavorite ? Icons.star : Icons.star_border,
                color:
                    discussion.isFavorite
                        ? const Color(0xFF4CD964)
                        : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  discussion.toggleFavorite();
                  _saveDiscussions();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showDiscussionOptions(discussion),
            ),
          ],
        ),
        onTap: () => setState(() => _currentDiscussion = discussion),
      ),
    );
  }

  void _showDiscussionOptions(Discussion discussion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.category, color: Colors.white),
                title: Text(
                  'Change category',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCategorySelector();
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download, color: Colors.white),
                title: Text(
                  'Export as text',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final text = discussion.exportToText();
                  await Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Discussion exported to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete discussion',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDiscussion(discussion);
                },
              ),
            ],
          ),
    );
  }

  void _deleteDiscussion(Discussion discussion) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Delete discussion?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _discussions.remove(discussion);
                    if (_currentDiscussion == discussion) {
                      _currentDiscussion = null;
                    }
                    _saveDiscussions();
                  });
                },
              ),
            ],
          ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 16),
                Text(
                  'Add new category',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter category name',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.edit, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The category will be available for all discussions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    PredefinedPhrases.addCustomCategory(controller.text);
                    setState(() {});
                  }
                  Navigator.pop(context);
                },
              ),
            ],
            actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.copy, color: Colors.white),
                title: Text('Copy text', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Text copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.translate, color: Colors.white),
                title: Text(
                  'Copy translation',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.translation));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Translation copied to clipboard')),
                  );
                },
              ),
              if (message.isUser)
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text(
                    'Edit message',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(message);
                  },
                ),
              if (message.isUser)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
            ],
          ),
    );
  }

  void _showEditMessageDialog(Message message) {
    final TextEditingController controller = TextEditingController(
      text: message.text,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Edit message', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Edit your message',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Save', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.pop(context);
                  _editMessage(message, controller.text);
                },
              ),
            ],
          ),
    );
  }

  void _editMessage(Message message, String newText) {
    if (newText.isEmpty || newText == message.text) return;
    setState(() {
      final index = _currentDiscussion!.messages.indexOf(message);
      _currentDiscussion!.messages[index] = Message(
        text: newText,
        translation: message.translation,
        timestamp: message.timestamp,
        isUser: message.isUser,
        detectedLanguage: message.detectedLanguage,
      );
      _text = newText;
      _translateText();
    });
  }

  void _deleteMessage(Message message) {
    setState(() {
      _currentDiscussion!.messages.remove(message);
      _saveDiscussions();
    });
  }
}
