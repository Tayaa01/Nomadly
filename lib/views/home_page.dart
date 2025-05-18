import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import SystemNavigator
import 'package:http/http.dart'
    as http; // Added import for http.ClientException
import '../widgets/app_drawer.dart';
import '../widgets/modern_app_bar.dart'; // Import the new modern app bar
import '../services/travel_services.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/tip.dart';
import '../services/tips_service.dart'; // Make sure this import is correct
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../providers/destination_provider.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shimmer/shimmer.dart'; // Add shimmer package for skeleton UI

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  final TipsService _tipsService = TipsService(); // Create a local instance

  // Break down loading states by section
  bool _isLoadingUser = true;
  bool _isLoadingFlights = true;
  bool _isLoadingHotels = true;
  bool _isLoadingTips = true;
  bool _isRefreshing = false;

  User? _user;
  List<Map<String, dynamic>> _flights = [];
  List<Map<String, dynamic>> _hotels = [];
  Timer? _autoRefreshTimer;
  DateTime? _lastUpdated;
  String? _errorMessage;
  Map<String, dynamic> _countryImages =
      {}; // Add this to store country images data

  @override
  void initState() {
    super.initState();
    _loadCountryImages(); // Load country images first (quick local operation)
    _progressiveLoadData(); // Start progressive loading

    // Set up auto-refresh every 5 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isRefreshing && mounted) {
        _silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // New method for progressive loading
  Future<void> _progressiveLoadData() async {
    if (!mounted) return;

    final destinationProvider = Provider.of<DestinationProvider>(
      context,
      listen: false,
    );

    if (!destinationProvider.hasManuallySelectedCountry) {
      destinationProvider.setSelectedCountry("Japan");
    }
    await destinationProvider.initializeCountriesIfNeeded();

    try {
      await _loadUserProfile(destinationProvider);

      // Use forceRefresh: false by default to try cache first
      await _loadDestinationDataParallel(
        destinationProvider.selectedCountry,
        destinationProvider: destinationProvider,
      );

      if (destinationProvider.selectedCountry != null) {
        _loadTipsCategories(destinationProvider.selectedCountry!);
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTips = false;
          });
        }
      }
    } catch (e) {
      print('Error during progressive loading: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load some data: $e';
        });
      }
    }
  }

  // Load user profile separately
  Future<void> _loadUserProfile(DestinationProvider destinationProvider) async {
    try {
      final user = await _userService.getUserProfile();

      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });

        if (user.countryCode.isNotEmpty) {
          String userCountry = _mapCountryCodeToName(user.countryCode);
          destinationProvider.setInitialCountry(userCountry);
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          if (e.toString().contains('401')) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            authProvider.logout().then((_) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
            });
          } else {
            _errorMessage = 'Failed to load user profile: $e';
          }
        });
      }
    }
  }

  // Load flights and hotels in parallel
  Future<void> _loadDestinationDataParallel(
    String? destination, {
    required DestinationProvider destinationProvider,
    bool forceRefresh = false,
  }) async {
    print(
      '[HomePage] _loadDestinationDataParallel called with destination: $destination, forceRefresh: $forceRefresh',
    );
    if (!mounted) {
      print(
        '[HomePage] _loadDestinationDataParallel returning early: not mounted',
      );
      return;
    }

    const String hardcodedOrigin = "Tunisia";

    if (destination == null) {
      setState(() {
        _isLoadingFlights = false;
        _isLoadingHotels = false;
        _flights = [];
        _hotels = [];
        _errorMessage = null;
      });
      print(
        '[HomePage] _loadDestinationDataParallel returning early: destination is null',
      );
      return;
    }

    if (destination.toLowerCase() == hardcodedOrigin.toLowerCase()) {
      print(
        '[HomePage] Origin and destination are the same ($destination). Skipping flight/hotel search.',
      );
      setState(() {
        _isLoadingFlights = false;
        _isLoadingHotels = false;
        _flights = [];
        _hotels = [];
        _errorMessage =
            'Please select a different country to search for flights and hotels from $hardcodedOrigin.';
      });
      return;
    }

    if (!forceRefresh &&
        destinationProvider.cachedDataCountry == destination &&
        destinationProvider.cachedFlights.isNotEmpty) {
      print('[HomePage] Using cached data for $destination');
      if (mounted) {
        setState(() {
          _flights = List.from(destinationProvider.cachedFlights);
          _hotels = List.from(destinationProvider.cachedHotels);
          _isLoadingFlights = false;
          _isLoadingHotels = false;
          _lastUpdated = DateTime.now();
          _errorMessage = null;
        });
      }
      return;
    }

    print(
      '[HomePage] Cache miss or forceRefresh for $destination. Fetching from API.',
    );
    setState(() {
      _isLoadingFlights = true;
      _isLoadingHotels = true;
      _errorMessage = null;
    });

    try {
      print(
        '[HomePage] Fetching flights and hotels for: $destination (from $hardcodedOrigin)',
      );
      final results = await Future.wait([
        TravelServices.fetchFlights(destination),
        TravelServices.fetchHotels(destination),
      ]);

      if (mounted) {
        print('[HomePage] Flights fetched: ${results[0]}');
        print('[HomePage] Hotels fetched: ${results[1]}');
        setState(() {
          _flights = results[0];
          _isLoadingFlights = false;
          _hotels = results[1];
          _isLoadingHotels = false;
          _lastUpdated = DateTime.now();
        });
        destinationProvider.updateCache(destination, results[0], results[1]);
      }
    } catch (e) {
      print('Error loading destination data for $destination: $e');
      if (mounted) {
        setState(() {
          _isLoadingFlights = false;
          _isLoadingHotels = false;
          if (e is http.ClientException) {
            _errorMessage = e.message;
          } else {
            _errorMessage =
                'Failed to load flight/hotel data for $destination: ${e.toString()}';
          }
        });
      }
    }
  }

  // Load tips categories
  Future<void> _loadTipsCategories(String country) async {
    try {
      await _tipsService.getCategoriesForCountry(country);
      if (mounted) {
        setState(() {
          _isLoadingTips = false;
        });
      }
    } catch (e) {
      print('Error loading tips: $e');
      if (mounted) {
        setState(() {
          _isLoadingTips = false;
        });
      }
    }
  }

  // Silent refresh for auto-updates
  Future<void> _silentRefresh() async {
    if (!mounted) return;

    print('[HomePage] Performing silent refresh...');
    setState(() {
      _isRefreshing = true;
    });

    try {
      final destinationProvider = Provider.of<DestinationProvider>(
        context,
        listen: false,
      );
      if (destinationProvider.selectedCountry != null) {
        await _loadDestinationDataParallel(
          destinationProvider.selectedCountry,
          destinationProvider: destinationProvider,
          forceRefresh: true,
        );
      }

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Silent refresh error: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Regular full refresh from pull-to-refresh
  Future<void> _loadData() async {
    print('[HomePage] Performing pull-to-refresh...');
    final destinationProvider = Provider.of<DestinationProvider>(
      context,
      listen: false,
    );

    if (destinationProvider.selectedCountry != null) {
      print(
        '[HomePage] Clearing cache for ${destinationProvider.selectedCountry} before pull-to-refresh.',
      );
      destinationProvider.clearCacheForCountry(
        destinationProvider.selectedCountry!,
      );
    }

    setState(() {
      _isLoadingUser = true;
      _isLoadingFlights = true;
      _isLoadingHotels = true;
      _isLoadingTips = true;
      _errorMessage = null;
    });

    await _progressiveLoadData();
  }

  // Load country images JSON
  Future<void> _loadCountryImages() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/country_images.json',
      );
      setState(() {
        _countryImages = json.decode(jsonString);
      });
    } catch (e) {
      print('Error loading country images: $e');
    }
  }

  String _mapCountryCodeToName(String countryCode) {
    final Map<String, String> codeToName = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'FR': 'France',
      'IT': 'Italy',
      'ES': 'Spain',
      'DE': 'Germany',
      'JP': 'Japan',
      'CN': 'China',
      'AU': 'Australia',
      'CA': 'Canada',
      'BR': 'Brazil',
      'IN': 'India',
      'TN': 'Tunisia',
      'MA': 'Morocco',
      'EG': 'Egypt',
      'TH': 'Thailand',
      'KR': 'South Korea',
      'MX': 'Mexico',
    };

    return codeToName[countryCode] ?? countryCode;
  }

  Future<void> _onCountrySelected(String country) async {
    if (!mounted) return;

    final destinationProvider = Provider.of<DestinationProvider>(
      context,
      listen: false,
    );

    if (country == destinationProvider.selectedCountry &&
        !destinationProvider.cachedFlights.isEmpty) {
      print(
        '[HomePage] Country $country already selected and data likely cached/displayed. Skipping redundant load.',
      );
      return;
    }

    destinationProvider.setSelectedCountry(country);

    setState(() {
      _isLoadingTips = true;
    });

    await _loadDestinationDataParallel(
      country,
      destinationProvider: destinationProvider,
    );
    await _loadTipsCategories(country);
  }

  Future<void> _openLink(String? url) async {
    if (url == null) return;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  List<String> _getHotelImagesForCountry(String country) {
    final List<String> defaultHotelImages = [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1000',
      'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?q=80&w=1000',
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=1000',
      'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?q=80&w=1000',
      'https://images.unsplash.com/photo-1606046604972-77cc76aee944?q=80&w=1000',
    ];

    country = country.trim();

    String countryKey = '';
    for (String key in _countryImages.keys) {
      if (key.toLowerCase() == country.toLowerCase() ||
          country.toLowerCase().contains(key.toLowerCase())) {
        countryKey = key;
        break;
      }
    }

    if (countryKey.isNotEmpty &&
        _countryImages.containsKey(countryKey) &&
        _countryImages[countryKey]['hotels'] is List &&
        (_countryImages[countryKey]['hotels'] as List).isNotEmpty) {
      return (_countryImages[countryKey]['hotels'] as List).cast<String>();
    }

    return defaultHotelImages;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        appBar: ModernAppBar(
          title: 'Nomadly',
          isDarkMode: isDarkMode,
          centerTitle: false,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: isDarkMode ? Colors.white : Colors.black,
              onPressed: () {
                // Notification handling
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              color: isDarkMode ? Colors.white : Colors.black,
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
        drawer: const AppDrawer(currentRoute: '/home'),
        body:
            _errorMessage != null
                ? _buildErrorView()
                : _buildProgressiveContentView(
                  Provider.of<DestinationProvider>(context),
                ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Exit App',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to exit the app?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'No',
                    style: TextStyle(color: Color(0xFF4CD964)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGreetingSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSelectorSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 80,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCardsSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressiveContentView(DestinationProvider destinationProvider) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4CD964),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _isLoadingUser
                      ? _buildUserGreetingSkeleton()
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_getTimeOfDay()}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _user != null
                                      ? '${_user!.firstName} 👋'
                                      : 'Explorer 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          if (_lastUpdated != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Last updated: ${_formatLastUpdated(_lastUpdated!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child:
                  destinationProvider.availableCountries.isEmpty
                      ? _buildDestinationSelectorSkeleton()
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explore Destinations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImprovedDestinationSelector(
                            destinationProvider,
                          ),
                        ],
                      ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _isLoadingFlights
                      ? _buildFlightCardSkeleton()
                      : _flights.isEmpty
                      ? destinationProvider.selectedCountry != null
                          ? _buildEmptyState(
                            'No flight data available for ${destinationProvider.selectedCountry}',
                          )
                          : const SizedBox.shrink()
                      : _buildFeaturedFlightsContent(destinationProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _isLoadingHotels
                      ? _buildHotelCardsSkeleton()
                      : _hotels.isEmpty
                      ? destinationProvider.selectedCountry != null
                          ? _buildEmptyState(
                            'No hotel data available for ${destinationProvider.selectedCountry}',
                          )
                          : const SizedBox.shrink()
                      : _buildHotelsContent(destinationProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16.0,
                0.0,
                16.0,
                16.0,
              ), // Reduced top padding
              child:
                  _isLoadingTips
                      ? _buildTipsSkeleton()
                      : destinationProvider.selectedCountry == null
                      ? const SizedBox.shrink()
                      : _buildIntegratedTipsSection(destinationProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/planner');
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CD964), Color(0xFF34A853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Travel Planner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plan your perfect trip with our personalized recommendations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: GestureDetector(
                onTap:
                    () => Navigator.pushNamed(context, '/currency-converter'),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF333333), Color(0xFF1E1E1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CD964).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CD964).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.currency_exchange,
                          color: Color(0xFF4CD964),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currency Converter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Scan bills and convert currencies instantly',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF4CD964),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedFlightsContent(DestinationProvider destinationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Featured Flights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isRefreshing)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          title:
              _flights[0]['title'] ??
              'Flight to ${destinationProvider.selectedCountry}',
          subtitle:
              _flights[0]['price'] != null
                  ? 'From ${_flights[0]['price']}'
                  : _flights[0]['snippet'] != null
                  ? 'Details: ${_formatSnippet(_flights[0]['snippet'])}'
                  : 'Check prices online',
          imageUrl: 'assets/images/flight.jpg',
          networkImageUrl: _getDestinationImage(
            destinationProvider.selectedCountry ?? '',
            true,
            false,
          ),
          onTap: () => _openLink(_flights[0]['link']),
          height: 200,
          maxWidth: double.infinity,
        ),
      ],
    );
  }

  Widget _buildHotelsContent(DestinationProvider destinationProvider) {
    List<String> hotelImages =
        destinationProvider.selectedCountry != null
            ? _getHotelImagesForCountry(destinationProvider.selectedCountry!)
            : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Popular Hotels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isRefreshing)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hotels.length > 3 ? 3 : _hotels.length,
            itemBuilder: (context, index) {
              final hotel = _hotels[index];
              String? networkImageUrl;
              if (hotelImages.isNotEmpty) {
                networkImageUrl = hotelImages[index % hotelImages.length];
              } else {
                networkImageUrl = _getDestinationImage(
                  destinationProvider.selectedCountry ?? '',
                  false,
                  true,
                );
              }

              return _buildHotelCard(
                name:
                    hotel['title'] ??
                    'Hotel in ${destinationProvider.selectedCountry}',
                price: hotel['price'] ?? 'Check prices',
                snippet: hotel['snippet'],
                imageUrl: 'assets/images/hotel.jpg',
                networkImageUrl: networkImageUrl,
                onTap: () => _openLink(hotel['link']),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSnippet(String? snippet) {
    if (snippet == null || snippet.isEmpty) return '';

    if (snippet.length > 60) {
      return '${snippet.substring(0, 60)}...';
    }

    return snippet;
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }

  Widget _buildHotelCard({
    required String name,
    required String price,
    String? snippet,
    required String imageUrl,
    String? networkImageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF333333),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child:
                  networkImageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: networkImageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Image.asset(imageUrl, fit: BoxFit.cover),
                        errorWidget:
                            (context, url, error) =>
                                Image.asset(imageUrl, fit: BoxFit.cover),
                      )
                      : Image.asset(imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.length > 18 ? '${name.substring(0, 18)}...' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (snippet != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      snippet.length > 45
                          ? '${snippet.substring(0, 45)}...'
                          : snippet,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF4CD964),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    String? networkImageUrl,
    required double height,
    required double maxWidth,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: maxWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  networkImageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: networkImageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Image.asset(imageUrl, fit: BoxFit.cover),
                        errorWidget:
                            (context, url, error) =>
                                Image.asset(imageUrl, fit: BoxFit.cover),
                      )
                      : Image.asset(imageUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.length > 30
                          ? '${title.substring(0, 30)}...'
                          : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD964),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Featured',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovedDestinationSelector(
    DestinationProvider destinationProvider,
  ) {
    final int totalCountries = min(
      20,
      destinationProvider.availableCountries.length,
    );
    final int itemsPerRow = (totalCountries / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showAllCountriesDialog(destinationProvider),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CD964).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF4CD964)),
                const SizedBox(width: 12),
                Text(
                  'Search destinations...',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (destinationProvider.selectedCountry != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CD964).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CD964), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4CD964)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Destination',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destinationProvider.selectedCountry!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isRefreshing)
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(left: 8),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF4CD964),
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
          const Text(
            'Explore Other Destinations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 88,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                itemsPerRow +
                    (destinationProvider.availableCountries.length > 20
                        ? 1
                        : 0),
                (columnIndex) {
                  if (columnIndex == itemsPerRow &&
                      destinationProvider.availableCountries.length > 20) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(height: 36),
                          GestureDetector(
                            onTap:
                                () => _showAllCountriesDialog(
                                  destinationProvider,
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF4CD964,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.more_horiz,
                                    color: Color(0xFF4CD964),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'More',
                                    style: TextStyle(color: Color(0xFF4CD964)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (columnIndex <
                            destinationProvider.availableCountries.length)
                          _buildCountryButton(
                            destinationProvider.availableCountries[columnIndex],
                            destinationProvider,
                          ),
                        if (columnIndex + itemsPerRow < totalCountries)
                          _buildCountryButton(
                            destinationProvider.availableCountries[columnIndex +
                                itemsPerRow],
                            destinationProvider,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryButton(
    String country,
    DestinationProvider destinationProvider,
  ) {
    final isSelected = country == destinationProvider.selectedCountry;

    return GestureDetector(
      onTap: _isRefreshing ? null : () => _onCountrySelected(country),
      child: Container(
        width: 100, // Fixed width for all country buttons
        alignment: Alignment.center, // Center the text
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CD964) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF4CD964).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          country,
          overflow: TextOverflow.ellipsis, // Handle long country names
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAllCountriesDialog(DestinationProvider destinationProvider) {
    final searchController = TextEditingController();
    List<String> filteredCountries = List.from(
      destinationProvider.availableCountries,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search countries...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF4CD964),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF333333),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              filteredCountries = List.from(
                                destinationProvider.availableCountries,
                              );
                            } else {
                              filteredCountries =
                                  destinationProvider.availableCountries
                                      .where(
                                        (country) => country
                                            .toLowerCase()
                                            .contains(value.toLowerCase()),
                                      )
                                      .toList();
                            }
                          });
                        },
                      ),
                    ),
                    if (filteredCountries.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No countries found matching "${searchController.text}"',
                            style: TextStyle(color: Colors.grey[400]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = filteredCountries[index];
                            final isSelected =
                                country == destinationProvider.selectedCountry;

                            return ListTile(
                              title: Text(
                                country,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              leading: const Icon(
                                Icons.place,
                                color: Color(0xFF4CD964),
                              ),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4CD964),
                                      )
                                      : null,
                              onTap: () {
                                Navigator.pop(context);
                                _onCountrySelected(country);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _getDestinationImage(
    String destination,
    bool isFlightImage,
    bool isHotelImage,
  ) {
    if (_countryImages.isEmpty) {
      if (isFlightImage) {
        return 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=1000';
      }
      if (isHotelImage) {
        return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1000';
      }
      return 'https://images.unsplash.com/photo-1503220317375-aaad61436b1b?q=80&w=1000';
    }

    String countryKey = '';
    for (String key in _countryImages.keys) {
      if (key.toLowerCase() == destination.toLowerCase() ||
          destination.toLowerCase().contains(key.toLowerCase())) {
        countryKey = key;
        break;
      }
    }

    if (countryKey.isNotEmpty && _countryImages.containsKey(countryKey)) {
      if (isFlightImage && _countryImages[countryKey].containsKey('airline')) {
        return _countryImages[countryKey]['airline'];
      }

      if (isHotelImage &&
          _countryImages[countryKey].containsKey('hotels') &&
          _countryImages[countryKey]['hotels'] is List &&
          (_countryImages[countryKey]['hotels'] as List).isNotEmpty) {
        final hotelImages = _countryImages[countryKey]['hotels'] as List;
        return hotelImages[0];
      }

      if (_countryImages[countryKey].containsKey('tourism') &&
          _countryImages[countryKey]['tourism'] is List &&
          (_countryImages[countryKey]['tourism'] as List).isNotEmpty) {
        final tourismImages = _countryImages[countryKey]['tourism'] as List;
        return tourismImages[0];
      }
    }

    if (isFlightImage) {
      return 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=1000';
    }

    if (isHotelImage) {
      return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1000';
    }

    return 'https://images.unsplash.com/photo-1503220317375-aaad61436b1b?q=80&w=1000';
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedTipsSection(DestinationProvider destinationProvider) {
    return FutureBuilder<List<String>>(
      future: _tipsService.getCategoriesForCountry(
        destinationProvider.selectedCountry!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Travel Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Travel Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildEmptyState(
                'No travel tips available for ${destinationProvider.selectedCountry}',
              ),
            ],
          );
        }

        final categories = snapshot.data!;
        final selectedCategory = categories.isNotEmpty ? categories[0] : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Travel Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    destinationProvider.setTipCategory(selectedCategory);
                    Navigator.pushNamed(context, '/tips');
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF4CD964),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedCategory != null)
              FutureBuilder<List<Tip>>(
                future: _tipsService.getTipsByCountryAndCategory(
                  destinationProvider.selectedCountry!,
                  selectedCategory,
                ),
                builder: (context, tipsSnapshot) {
                  if (!tipsSnapshot.hasData || tipsSnapshot.data!.isEmpty) {
                    return _buildTipPreviewCard(
                      category: selectedCategory,
                      content:
                          'Tap to see tips about ${destinationProvider.selectedCountry}.',
                      onTap: () {
                        destinationProvider.setTipCategory(selectedCategory);
                        Navigator.pushNamed(context, '/tips');
                      },
                    );
                  }

                  final tip = tipsSnapshot.data!.first;
                  return _buildTipPreviewCard(
                    category: tip.category,
                    content: tip.content,
                    onTap: () {
                      destinationProvider.setTipCategory(tip.category);
                      Navigator.pushNamed(context, '/tips');
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: selectedCategory == categories[index],
                      selectedColor: const Color(0xFF4CD964),
                      backgroundColor: const Color(0xFF333333),
                      labelStyle: TextStyle(
                        color:
                            selectedCategory == categories[index]
                                ? Colors.black
                                : Colors.white,
                      ),
                      onSelected: (_) {
                        destinationProvider.setTipCategory(categories[index]);
                        Navigator.pushNamed(context, '/tips');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipPreviewCard({
    required String category,
    required String content,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CD964).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Color(0xFF4CD964),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Read more',
                  style: TextStyle(
                    color: Color(0xFF4CD964),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Color(0xFF4CD964), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
