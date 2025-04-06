import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/travel_services.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/tip.dart';
import '../services/deals_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../providers/destination_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
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
      if (!_isLoading && !_isRefreshing) {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get destination provider
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      
      // Load user profile
      try {
        final user = await _userService.getUserProfile();
        setState(() {
          _user = user;
        });
        
        // Set user's country in the provider if it's the first time
        if (!destinationProvider.hasInitializedCountry && user.countryCode.isNotEmpty) {
          String userCountry = _mapCountryCodeToName(user.countryCode);
          destinationProvider.setInitialCountry(userCountry);
        }
      } catch (e) {
        print('Error loading user profile: $e');
        // Continue even if user profile fails
      }

      // Load destination data after ensuring provider is initialized
      if (destinationProvider.selectedCountry != null) {
        await _loadDestinationData(destinationProvider.selectedCountry!);
      }

      setState(() {
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }
  
  // Silent refresh for auto-updates
  Future<void> _silentRefresh() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
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
        });
      }
    }
  }

  Future<void> _onCountrySelected(String country) async {
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
                Navigator.pushReplacementNamed(context, '/tips');
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
                          onTap: () => Navigator.pushNamed(context, '/profile'),
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

            // Destination Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _isRefreshing && destinationProvider.selectedCountry != null ? 0.6 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: destinationProvider.availableCountries.length,
                          itemBuilder: (context, index) {
                            final country = destinationProvider.availableCountries[index];
                            final isSelected = country == destinationProvider.selectedCountry;
                            
                            return GestureDetector(
                              onTap: _isRefreshing 
                                  ? null 
                                  : () => _onCountrySelected(country),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8.0),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected && _isRefreshing)
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      ),
                                    Text(
                                      country,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
                  : _buildFeaturedFlightsSection(),
            ),

            // Popular Hotels Section
            SliverToBoxAdapter(
              child: _hotels.isEmpty 
                  ? destinationProvider.selectedCountry != null && !_isRefreshing
                      ? _buildEmptyState('No hotel data available for ${destinationProvider.selectedCountry}') 
                      : const SizedBox.shrink()
                  : _buildHotelsSection(),
            ),

            // Travel Tips Section with integrated Tips
            SliverToBoxAdapter(
              child: destinationProvider.selectedCountry == null 
                  ? const SizedBox.shrink()
                  : _buildIntegratedTipsSection(destinationProvider),
            ),

            // Currency services promo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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

  Widget _buildFeaturedFlightsSection() {
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
                title: _flights[0]['title'] ?? 'Flight to ${Provider.of<DestinationProvider>(context).selectedCountry}',
                subtitle: _flights[0]['price'] != null 
                    ? 'From ${_flights[0]['price']}' 
                    : _flights[0]['snippet'] != null
                        ? 'Details: ${_formatSnippet(_flights[0]['snippet'])}' 
                        : 'Check prices online',
                imageUrl: 'assets/images/flight.jpg',
                networkImageUrl: _getImageFromText('flight to ${Provider.of<DestinationProvider>(context).selectedCountry}'),
                onTap: () {
                  if (_flights[0]['link'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening flight details...')),
                    );
                  }
                },
                height: 200,
                maxWidth: constraints.maxWidth,
              );
            }
          ),
        ],
      ),
    );
  }
  
  Widget _buildHotelsSection() {
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
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hotels.length > 3 ? 3 : _hotels.length,
              itemBuilder: (context, index) {
                final hotel = _hotels[index];
                return _buildHotelCard(
                  name: hotel['title'] ?? 'Hotel in ${Provider.of<DestinationProvider>(context).selectedCountry}',
                  price: hotel['price'] ?? 'Check prices',
                  snippet: hotel['snippet'],
                  imageUrl: 'assets/images/hotel.jpg',
                  networkImageUrl: _getImageFromText('hotel in ${hotel['title'] ?? Provider.of<DestinationProvider>(context).selectedCountry}'),
                  onTap: () {
                    if (hotel['link'] != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening hotel details...')),
                      );
                    }
                  },
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
      future: TipsService.getCategoriesForCountry(destinationProvider.selectedCountry!),
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
                      // Pass current destination to tips page
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
                  future: TipsService.getTipsByCountryAndCategory(
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
      onTap: onTap,
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
    // Replace spaces with plus signs for URL
    final formattedQuery = query.replaceAll(' ', '+');
    
    // Use Unsplash API for random images based on the query
    return 'https://source.unsplash.com/400x300/?$formattedQuery';
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
              height: 100,
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.length > 20 ? '${name.substring(0, 20)}...' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (snippet != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      snippet.length > 50 ? '${snippet.substring(0, 50)}...' : snippet,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
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
}
