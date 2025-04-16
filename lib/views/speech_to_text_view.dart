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
import '../widgets/app_drawer.dart';  // Change import from custom_bottom_nav to app_drawer
import 'package:shimmer/shimmer.dart'; // Import shimmer package

class SpeechToTextView extends StatefulWidget {
  const SpeechToTextView({super.key});

  @override
  _SpeechToTextViewState createState() => _SpeechToTextViewState();
}

class _SpeechToTextViewState extends State<SpeechToTextView> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late TtsService _ttsService;
  late SharedPreferences _prefs;
  bool _isListening = false;
  String _text = 'Say something';
  String _translatedText = '';
  late AnimationController _animationController;
  Timer? _debounce;
  bool _isRequestPending = false;
  List<Discussion> _discussions = [];
  Discussion? _currentDiscussion;
  final TextEditingController _messageController = TextEditingController();

  String _selectedSourceLanguage = 'en';
  String _selectedTargetLanguage = 'fr';
  final String _searchQuery = '';
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
    'en', 'fr', 'es', 'de', 'it', 'zh', 'ja', 'ko', 'ru', 'pt'
    // Add other supported languages here
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _ttsService = TtsService();

    // Start loading immediately and don't wait for it to complete
    _initializePrefs();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Add periodic cleanup
    Timer.periodic(const Duration(hours: 1), (_) => _cleanupOldDiscussions());
  }

  Future<void> _initializePrefs() async {
    try {
      print('Initializing SharedPreferences');
      _prefs = await SharedPreferences.getInstance();

      // Now load discussions after prefs is initialized
      await _loadDiscussions();

      // Force UI update after discussions are loaded
      if (mounted) {
        setState(() {
          print('State updated after loading discussions');
        });
      }
    } catch (e) {
      print('Error in _initializePrefs: $e');
    }
  }

  Future<void> _loadDiscussions() async {
    try {
      // Check if the key exists and print all available keys for debugging
      final keys = _prefs.getKeys();
      print('Available SharedPreferences keys: $keys');
      print('Checking for "discussions" key: ${_prefs.containsKey('discussions')}');

      final discussionsJson = _prefs.getStringList('discussions') ?? [];
      print('Loading ${discussionsJson.length} discussions from SharedPreferences');

      if (discussionsJson.isEmpty) {
        print('No discussions found in SharedPreferences');
        _discussions = [];
        return;
      }

      final loadedDiscussions = <Discussion>[];

      for (var json in discussionsJson) {
        try {
          final discussion = Discussion.fromJson(jsonDecode(json));
          loadedDiscussions.add(discussion);
        } catch (e) {
          print('Error parsing discussion JSON: $e');
        }
      }

      print('Successfully loaded ${loadedDiscussions.length} discussions');

      // Update the discussions list and trigger a UI update
      setState(() {
        _discussions = loadedDiscussions;
      });

      _cleanupOldDiscussions();
    } catch (e) {
      print('Exception in _loadDiscussions: $e');
      setState(() {
        _discussions = [];
      });
    }
  }

  Future<void> _saveDiscussions() async {
    try {
      final discussionsJson = _discussions
          .map((discussion) => jsonEncode(discussion.toJson()))
          .toList();

      print('Saving ${discussionsJson.length} discussions to SharedPreferences');

      final result = await _prefs.setStringList('discussions', discussionsJson);

      if (result) {
        print('Discussions successfully saved to SharedPreferences');
      } else {
        print('Failed to save discussions to SharedPreferences');
      }

      // Verify save worked by reading back
      final saved = _prefs.getStringList('discussions') ?? [];
      print('Verified ${saved.length} discussions saved');
    } catch (e) {
      print('Exception in _saveDiscussions: $e');
    }
  }

  void _createNewDiscussion() {
    _showCategorySelector(createNew: true);
  }


  void _cleanupOldDiscussions() {
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

  Future<void> _translateText() async {
    if (_text.isEmpty || _text == 'Say something' || _isRequestPending) return;

    setState(() {
      _isRequestPending = true;
    });

    try {
      // Get the translation from the API
      final response = await _performOnlineTranslation();
      final translation = response['translation'] ?? 'Translation failed';
      
      // Cache the translation for potential future offline use
      await TranslationCacheService.cacheTranslation(
        _text,
        translation,
        _selectedSourceLanguage,
        _selectedTargetLanguage,
      );

      setState(() {
        _translatedText = translation;
        if (_currentDiscussion != null) {
          _currentDiscussion!.messages.add(Message(
            text: _text,
            translation: _translatedText,
            timestamp: DateTime.now(),
            isUser: true,
            detectedLanguage: _selectedSourceLanguage,
          ));
          _saveDiscussions();
        }
      });
    } catch (e) {
      print('Translation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: $e')),
      );
    } finally {
      setState(() {
        _isRequestPending = false;
      });
    }
  }

  // Add a skeleton loader for translation waiting
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF232323),
          highlightColor: const Color(0xFF4CD964).withOpacity(0.25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 32,
                width: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),
              Container(
                height: 18,
                width: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
              ),
              Container(
                height: 18,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          _currentDiscussion == null ? 'Translate' : _currentDiscussion!.category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _currentDiscussion == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => setState(() => _currentDiscussion = null),
              ),
        actions: _buildAppBarActions(),
      ),
      drawer: const AppDrawer(currentRoute: '/translation'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
          ),
        ),
        child: _isRequestPending
            ? _buildLoadingSkeleton()
            : _currentDiscussion == null
                ? _buildDiscussionsListView()
                : _buildDiscussionView(),
      ),
      floatingActionButton: _currentDiscussion == null
          ? FloatingActionButton(
              onPressed: _createNewDiscussion,
              backgroundColor: const Color(0xFF4CD964),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_currentDiscussion == null) {
      // For the discussions list screen - remove the online/offline toggle
      return [];
    } else {
      // For the discussion view, keep language selectors
      return [
        // Combined language selector button
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Show dialog with both language options
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text(
                      'Select Languages',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageSelectionButton(
                          'Source Language',
                          _selectedSourceLanguage,
                          () {
                            Navigator.pop(context);
                            _showLanguageSelector(true);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLanguageSelectionButton(
                          'Target Language',
                          _selectedTargetLanguage,
                          () {
                            Navigator.pop(context);
                            _showLanguageSelector(false);
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF4CD964)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedSourceLanguage.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF4CD964),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedTargetLanguage.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Category button
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CD964).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CD964).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCategorySelector(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PredefinedPhrases.categoryIcons[_currentDiscussion!.category] ?? Icons.label_outline,
                      color: const Color(0xFF4CD964),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentDiscussion!.category,
                      style: const TextStyle(
                        color: Color(0xFF4CD964),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }
  }

  // Helper method for language selection buttons
  Widget _buildLanguageSelectionButton(String label, String languageCode, VoidCallback onTap) {
    // Find language name from code
    String languageName = 'Unknown';
    for (var lang in _languages) {
      if (lang['code'] == languageCode) {
        languageName = lang['name']!;
        break;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF4CD964),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionsListView() {
    // Filter discussions without categories - no need for category filtering now
    final filteredDiscussions = _discussions.where((discussion) {
      if (_searchQuery.isEmpty) {
        return true; // Show all discussions since we're removing category filtering
      }

      final query = _searchQuery.toLowerCase();
      final matchesSearch = discussion.messages.any((message) =>
          message.text.toLowerCase().contains(query) ||
          message.translation.toLowerCase().contains(query));

      return matchesSearch;
    }).toList();

    return Column(
      children: [
        // Keep the info message with clear button
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted top margin
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Discussions are automatically deleted after 24 hours unless favorited',
                      style: TextStyle(color: Colors.blue[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmClearNonFavorites(),
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text('Clear Now', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red[400]!.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of discussions or empty state
        Expanded(
          child: filteredDiscussions.isEmpty
              ? _buildEmptyDiscussionsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDiscussions.length,
                  itemBuilder: (context, index) {
                    final discussion = filteredDiscussions[index];
                    return _buildStyledDiscussionItem(discussion);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyDiscussionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CD964).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.translate,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No discussions yet',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start a new conversation for translation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createNewDiscussion,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Discussion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDiscussionItem(Discussion discussion) {
    final lastMessage = discussion.messages.isNotEmpty ? discussion.messages.last : null;
    final hoursLeft = discussion.isFavorite ? null : 24 - DateTime.now().difference(discussion.createdAt).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _currentDiscussion = discussion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PredefinedPhrases.categoryIcons[discussion.category] ?? Icons.label_outline,
                        color: const Color(0xFF4CD964),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CD964),
                              borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 8),
                          if (hoursLeft != null)
                            Text(
                              'Expires in ${hoursLeft}h',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            discussion.isFavorite ? Icons.star : Icons.star_border,
                            color: discussion.isFavorite ? const Color(0xFF4CD964) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              discussion.toggleFavorite();
                              _saveDiscussions();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () => _showDiscussionOptions(discussion),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                if (lastMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  Text(
                    lastMessage.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.translation,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getTimeAgo(lastMessage.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionView() {
    return Column(
      children: [
        _buildStyledPredefinedPhrases(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _currentDiscussion!.messages.length,
            itemBuilder: (context, index) {
              final message = _currentDiscussion!.messages[index];
              return _buildStyledMessageBubble(message);
            },
          ),
        ),
        _buildStyledInputArea(),
      ],
    );
  }

  Widget _buildStyledPredefinedPhrases() {
    final phrases = PredefinedPhrases.phrasesByCategory[_currentDiscussion!.category] ?? [];
    if (phrases.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _onPredefinedPhraseSelected(phrase),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      phrase['text']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyledMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF4CD964)
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.black : Colors.white,
                  fontSize: 16,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: message.isUser
                    ? Colors.black.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message.translation,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (_supportedTtsLanguages.contains(
                      message.isUser ? _selectedTargetLanguage : message.detectedLanguage))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _speak(
                          message.isUser ? message.translation : message.text,
                          message.isUser ? _selectedTargetLanguage : message.detectedLanguage,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.volume_up,
                            color: message.isUser
                                ? Colors.black.withOpacity(0.5)
                                : Colors.white.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _getTimeAgo(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledInputArea() {
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
                        hintText: 'Type to translate...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _onTextSubmitted,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _listen,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? const Color(0xFF4CD964)
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _onTextSubmitted(_messageController.text),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _performOnlineTranslation() async {
    final String url = 'https://lingva.ml/api/v1/$_selectedSourceLanguage/$_selectedTargetLanguage/${Uri.encodeComponent(_text)}';

    print('Sending translation request with text: $_text');
    print('Source language: $_selectedSourceLanguage, Target language: _selectedTargetLanguage');
    final response = await http.get(Uri.parse(url));

    print('Received response with status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'translation': data['translation'] ?? 'Translation failed',
      };
    } else {
      final errorMessage = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to translate: ${response.statusCode}, Message: $errorMessage');
    }
  }

  void _showCategorySelector({bool createNew = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Make it taller
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add a header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Color(0xFF4CD964),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  createNew ? 'Select Category for New Discussion' : 'Change Category',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          // Categories list
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: PredefinedPhrases.phrasesByCategory.length,
              itemBuilder: (context, index) {
                final category = PredefinedPhrases.phrasesByCategory.keys.elementAt(index);
                return ListTile(
                  leading: Icon(
                    PredefinedPhrases.categoryIcons[category] ?? Icons.label_outline,
                    color: const Color(0xFF4CD964),
                    size: 24,
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Category'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CD964),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _showDiscussionOptions(Discussion discussion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Discussion Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          
          // Options
          _buildOptionTile(
            icon: Icons.category_outlined,
            color: const Color(0xFF4CD964),
            title: 'Change category',
            onTap: () {
              Navigator.pop(context);
              _showCategorySelector();
            },
          ),
          
          _buildOptionTile(
            icon: Icons.file_copy_outlined,
            color: Colors.blue,
            title: 'Export as text',
            onTap: () async {
              Navigator.pop(context);
              final text = discussion.exportToText();
              await Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Discussion copied to clipboard'),
                  backgroundColor: Color(0xFF333333),
                ),
              );
            },
          ),
          
          _buildOptionTile(
            icon: Icons.delete_outline,
            color: Colors.red,
            title: 'Delete discussion',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _deleteDiscussion(discussion);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon, 
    required Color color, 
    required String title, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDiscussion(Discussion discussion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Discussion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All messages in this discussion will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('DELETE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _confirmClearNonFavorites() {
    // Count how many non-favorite discussions would be deleted
    final nonFavoriteCount = _discussions.where((d) => !d.isFavorite).length;

    if (nonFavoriteCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No non-favorite discussions to clear'),
          backgroundColor: Color(0xFF333333),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Clear Discussions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will delete $nonFavoriteCount non-favorited discussion${nonFavoriteCount > 1 ? 's' : ''}.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(color: Colors.red[300], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('CLEAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _discussions.removeWhere((d) => !d.isFavorite);
                _saveDiscussions();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Non-favorite discussions cleared'),
                    backgroundColor: Color(0xFF333333),
                  ),
                );
              });
            },
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: const Color(0xFF4CD964),
            ),
            SizedBox(height: 16),
            Text(
              'Add new category',
              style: TextStyle(
                color: Colors.white,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.edit, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF4CD964), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF333333),
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
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
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
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Category',
              style: TextStyle(
                color: Colors.black,
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

  Future<void> _speak(String text, String language) async {
    if (text.isEmpty) return;
    
    // Show loading indicator while processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio...'),
        duration: Duration(milliseconds: 800),
        backgroundColor: Color(0xFF333333),
      ),
    );

    try {
      // Use the TTS service to speak the text
      await _ttsService.speak(text, language);
    } catch (e) {
      print('Error in _speak: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play audio: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _showLanguageSelector(bool isSource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.language,
                          color: Color(0xFF4CD964),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isSource ? 'Select Source Language' : 'Select Target Language',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF333333)),
            
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search languages',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    // Add filtering logic if needed
                  },
                ),
              ),
            ),
            
            // Languages list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  final isSelected = isSource 
                      ? _selectedSourceLanguage == language['code']
                      : _selectedTargetLanguage == language['code'];
                  final isTtsSupported = _supportedTtsLanguages.contains(language['code']);
                  
                  return InkWell(
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
                    child: Container(
                      color: isSelected ? const Color(0xFF4CD964).withOpacity(0.15) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language['name']!,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF4CD964) : Colors.white,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (!isTtsSupported)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Translation only',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CD964),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _messageController.dispose();
    _searchController.dispose();
    
    // Cancel any timers
    _debounce?.cancel();
    
    // Stop animation controller
    _animationController.dispose();
    
    // Close TTS service
    _ttsService.dispose();
    
    super.dispose();
  }
}