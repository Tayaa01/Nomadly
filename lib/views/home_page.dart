import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/travel_services.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/tip.dart';
import '../services/tips_service.dart'; // Make sure this import is correct
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../providers/destination_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  final TipsService _tipsService = TipsService(); // Create a local instance
  bool _isLoading = true;
  bool _isRefreshing = false;
  User? _user;
  List<Map<String, dynamic>> _flights = [];
  List<Map<String, dynamic>> _hotels = [];
  Timer? _autoRefreshTimer;
  DateTime? _lastUpdated;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Set up auto-refresh every 5 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isLoading && !_isRefreshing && mounted) {
        _silentRefresh();
      }
    });
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get destination provider
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      
      // Ensure countries are loaded in the provider
      await destinationProvider.initializeCountriesIfNeeded(); // Use the public method instead
      
      // Load user profile
      try {
        final user = await _userService.getUserProfile();
        
        // Only update state if the widget is still mounted
        if (mounted) {
          setState(() {
            _user = user;
          });
        
          // Set user's country in the provider if it's the first time
          if (!destinationProvider.hasInitializedCountry && user.countryCode.isNotEmpty) {
            String userCountry = _mapCountryCodeToName(user.countryCode);
            destinationProvider.setInitialCountry(userCountry);
          }
        }
      } catch (e) {
        print('Error loading user profile: $e');
        // Continue even if user profile fails
      }

      // Load destination data after ensuring provider is initialized
      if (destinationProvider.selectedCountry != null) {
        await _loadDestinationData(destinationProvider.selectedCountry!);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: $e';
        });
      }
    }
  }
  
  // Silent refresh for auto-updates
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      if (destinationProvider.selectedCountry != null) {
        final flights = await TravelServices.fetchFlights(destinationProvider.selectedCountry!);
        final hotels = await TravelServices.fetchHotels(destinationProvider.selectedCountry!);
        
        if (mounted) {
          setState(() {
            _flights = flights;
            _hotels = hotels;
            _lastUpdated = DateTime.now();
            _isRefreshing = false;
          });
        }
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

  String _mapCountryCodeToName(String countryCode) {
    // Map common country codes to names
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

  Future<void> _loadDestinationData(String destination) async {
    if (!mounted) return;
    
    try {
      setState(() {
        if (!_isLoading) _isRefreshing = true;
      });
      
      // Load flights for the destination
      final flights = await TravelServices.fetchFlights(destination);
      
      // Load hotels for the destination
      final hotels = await TravelServices.fetchHotels(destination);
      
      if (mounted) {
        setState(() {
          _flights = flights;
          _hotels = hotels;
          _isRefreshing = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading destination data: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          // Don't set error message for this to avoid disrupting the UI
        });
      }
    }
  }

  Future<void> _onCountrySelected(String country) async {
    if (!mounted) return;
    
    final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
    
    if (country == destinationProvider.selectedCountry) return;
    
    // Update the provider
    destinationProvider.setSelectedCountry(country);
    
    setState(() {
      // Clear existing data for instant UI feedback
      _flights = [];
      _hotels = [];
    });
    
    await _loadDestinationData(country);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DestinationProvider>(
      builder: (context, destinationProvider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _isLoading 
              ? _buildLoadingView()
              : _errorMessage != null 
                  ? _buildErrorView() 
                  : _buildContentView(destinationProvider),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                Navigator.pushReplacementNamed(context, '/deals'); // Update this navigation
              } else if (index == 2) {
                Navigator.pushReplacementNamed(context, '/currency-converter');
              } else if (index == 3) {
                Navigator.pushReplacementNamed(context, '/translation');
              } else if (index == 4) {
                Navigator.pushReplacementNamed(context, '/statistics');
              }
            },
          ),
        );
      }
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4CD964)),
          const SizedBox(height: 16),
          Text(
            'Loading your travel data...',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            Provider.of<DestinationProvider>(context).selectedCountry != null 
                ? 'Finding the best deals in ${Provider.of<DestinationProvider>(context).selectedCountry}' 
                : 'Discovering destinations for you',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
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

  Widget _buildContentView(DestinationProvider destinationProvider) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF4CD964),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                    Row(
                      children: [
                        if (_isRefreshing)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 16,
                            height: 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/expense-tracker',
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile')
                              .then((_) => _loadData()), // Refresh after returning from profile
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Last updated info
            if (_lastUpdated != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Last updated: ${_formatLastUpdated(_lastUpdated!)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Enhanced Destination Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
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
                    _buildImprovedDestinationSelector(destinationProvider),
                  ],
                ),
              ),
            ),

            // Featured Flights Section
            SliverToBoxAdapter(
              child: _flights.isEmpty 
                  ? destinationProvider.selectedCountry != null && !_isRefreshing
                      ? _buildEmptyState('No flight data available for ${destinationProvider.selectedCountry}')
                      : const SizedBox.shrink()
                  : _buildFeaturedFlightsSection(destinationProvider),
            ),

            // Popular Hotels Section
            SliverToBoxAdapter(
              child: _hotels.isEmpty 
                  ? destinationProvider.selectedCountry != null && !_isRefreshing
                      ? _buildEmptyState('No hotel data available for ${destinationProvider.selectedCountry}') 
                      : const SizedBox.shrink()
                  : _buildHotelsSection(destinationProvider),
            ),

            // Travel Tips Section with integrated Tips
            SliverToBoxAdapter(
              child: destinationProvider.selectedCountry == null 
                  ? const SizedBox.shrink()
                  : _buildIntegratedTipsSection(destinationProvider),
            ),

            // Travel Planner Promo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    // Use pushNamed instead of pushReplacementNamed to preserve the bottom nav state
                    // This pushes the Travel Planner screen on top of the current stack
                    Navigator.of(context).pushNamed('/planner');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CD964),
                          Color(0xFF34A853),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
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

            // Currency services promo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/currency-converter'),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF333333),
                          Color(0xFF1E1E1E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  Widget _buildFeaturedFlightsSection(DestinationProvider destinationProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildFeatureCard(
                title: _flights[0]['title'] ?? 'Flight to ${destinationProvider.selectedCountry}',
                subtitle: _flights[0]['price'] != null 
                    ? 'From ${_flights[0]['price']}' 
                    : _flights[0]['snippet'] != null
                        ? 'Details: ${_formatSnippet(_flights[0]['snippet'])}' 
                        : 'Check prices online',
                imageUrl: 'assets/images/flight.jpg',
                networkImageUrl: _getImageFromText('flight to ${destinationProvider.selectedCountry}'),
                onTap: () => _openLink(_flights[0]['link']),
                height: 200,
                maxWidth: constraints.maxWidth,
              );
            }
          ),
        ],
      ),
    );
  }
  
  Widget _buildHotelsSection(DestinationProvider destinationProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
            height: 200, // Increase this height from 180 to 200 to fix the overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hotels.length > 3 ? 3 : _hotels.length,
              itemBuilder: (context, index) {
                final hotel = _hotels[index];
                return _buildHotelCard(
                  name: hotel['title'] ?? 'Hotel in ${destinationProvider.selectedCountry}',
                  price: hotel['price'] ?? 'Check prices',
                  snippet: hotel['snippet'],
                  imageUrl: 'assets/images/hotel.jpg',
                  networkImageUrl: _getImageFromText('hotel in ${hotel['title'] ?? destinationProvider.selectedCountry}'),
                  onTap: () => _openLink(hotel['link']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedTipsSection(DestinationProvider destinationProvider) {
    return FutureBuilder<List<String>>(
      // Use the imported class name instead of direct access
      future: _tipsService.getCategoriesForCountry(destinationProvider.selectedCountry!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No travel tips available for ${destinationProvider.selectedCountry}');
        }
        
        final categories = snapshot.data!;
        final selectedCategory = categories.isNotEmpty ? categories[0] : null;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                      // Set the tip category and navigate to the tips screen
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
              
              // Preview one tip from the first category
              if (selectedCategory != null)
                FutureBuilder<List<Tip>>(
                  // Change this line to use the instance method instead of static access
                  future: _tipsService.getTipsByCountryAndCategory(
                    destinationProvider.selectedCountry!,
                    selectedCategory,
                  ),
                  builder: (context, tipsSnapshot) {
                    if (!tipsSnapshot.hasData || tipsSnapshot.data!.isEmpty) {
                      return _buildTipPreviewCard(
                        category: selectedCategory,
                        content: 'Tap to see tips about ${destinationProvider.selectedCountry}.',
                        onTap: () {
                          destinationProvider.setTipCategory(selectedCategory);
                          Navigator.pushNamed(context, '/tips');
                        },
                      );
                    }
                    
                    // Show first tip as preview
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
              
              const SizedBox(height: 12),
              
              // Category chips
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
                          color: selectedCategory == categories[index] 
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
          ),
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
      onTap: onTap, // This onTap should navigate to tips screen
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
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
                Icon(
                  Icons.arrow_forward,
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

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline, 
              color: Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
  
  String _getImageFromText(String query) {
    // Simplify the query to avoid complex URLs that may fail
    String simpleQuery;
    
    if (query.contains('flight')) {
      simpleQuery = 'airplane';
    } else if (query.contains('hotel')) {
      simpleQuery = 'hotel';
    } else {
      simpleQuery = 'travel';
    }
    
    // Use a more reliable source for random images (Picsum)
    // This avoids the 404 errors from Unsplash
    return 'https://picsum.photos/seed/${simpleQuery}${Random().nextInt(1000)}/400/300';
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
            // Increase the image height from 100 to 110
            SizedBox(
              height: 110,
              width: double.infinity,
              child: networkImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: networkImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
            // Adjust padding to prevent overflow
            Padding(
              padding: const EdgeInsets.all(10), // Reduced from 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.length > 18 ? '${name.substring(0, 18)}...' : name, // Reduce maximum length
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (snippet != null) ...[
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      snippet.length > 45 ? '${snippet.substring(0, 45)}...' : snippet, // Reduced from 50
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2), // Reduced from 4
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
            // Background image
            Positioned.fill(
              child: networkImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: networkImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
            // Gradient overlay
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
            // Content
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
                      title.length > 30 ? '${title.substring(0, 30)}...' : title,
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
                        fontSize: 16
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // "Featured" badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildImprovedDestinationSelector(DestinationProvider destinationProvider) {
    // Prepare all countries in paired rows
    final int totalCountries = min(20, destinationProvider.availableCountries.length);
    final int itemsPerRow = (totalCountries / 2).ceil();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar for countries
        InkWell(
          onTap: () => _showAllCountriesDialog(destinationProvider),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.3)),
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
        
        // Show selected country prominently if one is selected
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
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
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
        
        // Combined row approach that scrolls together
        SizedBox(
          height: 88, // Height for both rows
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                itemsPerRow + (destinationProvider.availableCountries.length > 20 ? 1 : 0),
                (columnIndex) {
                  // For the "More" button as the last column
                  if (columnIndex == itemsPerRow && destinationProvider.availableCountries.length > 20) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Empty space matching the height of a country button
                          const SizedBox(height: 36),
                          
                          // "More" button in the bottom row
                          GestureDetector(
                            onTap: () => _showAllCountriesDialog(destinationProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.more_horiz, color: Color(0xFF4CD964), size: 18),
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
                  
                  // Regular column of country items (one for top row, one for bottom row)
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row item
                        if (columnIndex < destinationProvider.availableCountries.length)
                          _buildCountryButton(
                            destinationProvider.availableCountries[columnIndex],
                            destinationProvider
                          ),
                        
                        // Bottom row item
                        if (columnIndex + itemsPerRow < totalCountries)
                          _buildCountryButton(
                            destinationProvider.availableCountries[columnIndex + itemsPerRow],
                            destinationProvider
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

  // Helper to build a single country button
  Widget _buildCountryButton(String country, DestinationProvider destinationProvider) {
    final isSelected = country == destinationProvider.selectedCountry;
    
    return GestureDetector(
      onTap: _isRefreshing ? null : () => _onCountrySelected(country),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4CD964) 
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF4CD964).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          country,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Fix the method for showing country suggestions

  // Fix the all countries dialog with search functionality
  void _showAllCountriesDialog(DestinationProvider destinationProvider) {
    // Controller for search
    final searchController = TextEditingController();
    // Create a local state for filtered countries
    List<String> filteredCountries = List.from(destinationProvider.availableCountries);
    
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
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF4CD964)),
                          filled: true,
                          fillColor: const Color(0xFF333333),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          // Update the filtered list based on search input
                          setState(() {
                            if (value.isEmpty) {
                              filteredCountries = List.from(destinationProvider.availableCountries);
                            } else {
                              filteredCountries = destinationProvider.availableCountries
                                  .where((country) => country.toLowerCase().contains(value.toLowerCase()))
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
                            final isSelected = country == destinationProvider.selectedCountry;
                            
                            return ListTile(
                              title: Text(
                                country,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              leading: const Icon(Icons.place, color: Color(0xFF4CD964)),
                              trailing: isSelected 
                                  ? const Icon(Icons.check_circle, color: Color(0xFF4CD964)) 
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
}
