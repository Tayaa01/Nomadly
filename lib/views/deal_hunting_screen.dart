import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/deals_service.dart';
import '../widgets/app_drawer.dart';
import '../viewmodels/currency_viewmodel.dart';

class DealHuntingScreen extends StatefulWidget {
  const DealHuntingScreen({super.key});

  @override
  State<DealHuntingScreen> createState() => _DealHuntingScreenState();
}

class _DealHuntingScreenState extends State<DealHuntingScreen> {
  bool _isLoading = false;
  bool _isDetectingLocation = true;
  List<Map<String, dynamic>> _recommendations = [];
  String? _errorMessage;
  String? _detectedCountry;
  String? _countryName;
  String _category = 'clothes';
  final TextEditingController _categoryController = TextEditingController(text: 'clothes');
  
  // Use the EXACT same preference keys as CurrencyViewModel
  static const String _kCountryCodePref = 'country_code';
  static const String _kCountryNamePref = 'country_name';

  @override
  void initState() {
    super.initState();
    _loadSavedCountryAndDetect();
  }

  // Fix the refresh issue by creating a method that clears preferences first
  Future<void> _forceRefreshCountry() async {
    setState(() {
      _isDetectingLocation = true;
      _errorMessage = null;
    });

    try {
      // First, clear the saved country preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCountryCodePref);
      await prefs.remove(_kCountryNamePref);
      
      // Create a new CurrencyViewModel instance (to avoid any caching issues)
      final currencyVM = CurrencyViewModel();
      
      // Call getUserLocation to detect the country
      await currencyVM.getUserLocation();
      
      if (mounted) {
        setState(() {
          _detectedCountry = currencyVM.currentCountryCode;
          _countryName = currencyVM.sourceCountryName;
          _isDetectingLocation = false;
        });
        
        print('Force refreshed country: $_countryName ($_detectedCountry)');
      }
      
      if (_detectedCountry == null) {
        _setDefaultCountry();
      }
    } catch (e) {
      print('Error force refreshing location: $e');
      if (mounted) {
        _setDefaultCountry();
      }
    }
  }

  // Regular method to get saved country
  Future<void> _loadSavedCountryAndDetect() async {
    setState(() {
      _isDetectingLocation = true;
      _errorMessage = null; // Clear any previous errors
    });

    try {
      // Create a new CurrencyViewModel for fresh detection
      final currencyVM = CurrencyViewModel();
      
      // Remove the forceRefresh parameter that doesn't exist
      await currencyVM.getUserLocation();
      
      // Get the updated country info
      if (mounted) {
        setState(() {
          _detectedCountry = currencyVM.currentCountryCode;
          _countryName = currencyVM.sourceCountryName;
          _isDetectingLocation = false;
        });
        
        print('Updated country detected: $_countryName ($_detectedCountry)');
      }
      
      // If we still don't have a country, use default
      if (_detectedCountry == null) {
        _setDefaultCountry();
      }
    } catch (e) {
      print('Error refreshing location: $e');
      if (mounted) {
        _setDefaultCountry();
      }
    }
  }

  // Helper to set default country if detection fails
  void _setDefaultCountry() {
    setState(() {
      _detectedCountry = 'US';
      _countryName = 'United States';
      _isDetectingLocation = false;
    });
  }

  // Use same method to set country as CurrencyViewModel
  Future<void> _setCountry(String code, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCountryCodePref, code);
      await prefs.setString(_kCountryNamePref, name);
      
      setState(() {
        _detectedCountry = code;
        _countryName = name;
      });
      
      print('Country set to: $name ($code)');
    } catch (e) {
      print('Error setting country: $e');
    }
  }
  
  Future<void> _fetchDeals() async {
    // Ensure we have a country code (either detected or default)
    final countryCode = _detectedCountry ?? 'US';
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DealsService.fetchDealsHunt(countryCode, _category);
      
      if (mounted) {
        // Safety check for recommendations
        List<Map<String, dynamic>> recommendations = [];
        
        if (response.containsKey('recommendations')) {
          // Safely convert the recommendations to the expected type
          final rawRecommendations = response['recommendations'];
          if (rawRecommendations is List) {
            recommendations = rawRecommendations
                .whereType<Map<String, dynamic>>()
                .cast<Map<String, dynamic>>()
                .toList();
          }
        }
        
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
          
          // Show error if we couldn't get any recommendations
          if (recommendations.isEmpty) {
            _errorMessage = 'No deals found for "$_category" in $_countryName.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load deals: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Deal Hunting',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/deal-hunting'),
      body: Column(
        children: [
          // Enhanced header section with gradients
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF1E1E1E).withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Nice illustration or icon for deal hunting
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CD964).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Color(0xFF4CD964),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find amazing deals for:',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _countryName ?? 'Your Location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showCountryPicker(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CD964).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _isDetectingLocation
                                  ? '...'
                                  : (_detectedCountry ?? 'US'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF4CD964),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced search field
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CD964).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.category,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What are you looking for?',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            _category = value;
                          },
                        ),
                      ),
                      // Search button with animation
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isDetectingLocation ? null : _fetchDeals,
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDetectingLocation 
                                  ? Colors.grey
                                  : const Color(0xFF4CD964),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(11),
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced category chips with horizontal scroll
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 16, bottom: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildEnhancedCategoryChip('clothes', Icons.shopping_bag),
                      _buildEnhancedCategoryChip('electronics', Icons.phone_android),
                      _buildEnhancedCategoryChip('shoes', Icons.hiking),
                      _buildEnhancedCategoryChip('furniture', Icons.chair),
                      _buildEnhancedCategoryChip('toys', Icons.toys),
                      _buildEnhancedCategoryChip('beauty', Icons.face),
                      _buildEnhancedCategoryChip('sports', Icons.sports_basketball),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message with improved styling
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Improved content area with transitions
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? _buildLoadingState()
                  : _recommendations.isEmpty && _errorMessage == null
                      ? _buildEnhancedEmptyState()
                      : _buildEnhancedDealsList(),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced category chip with icon
  Widget _buildEnhancedCategoryChip(String category, IconData icon) {
    final isSelected = _category == category;
    
    // Custom icons that better match the app's style
    IconData customIcon;
    switch (category) {
      case 'clothes':
        customIcon = Icons.checkroom_outlined;
        break;
      case 'electronics':
        customIcon = Icons.devices_outlined;
        break;
      case 'shoes':
        customIcon = Icons.format_paint_outlined;
        break;
      case 'furniture':
        customIcon = Icons.weekend_outlined;
        break;
      case 'toys':
        customIcon = Icons.toys_outlined;
        break;
      case 'beauty':
        customIcon = Icons.spa_outlined;
        break;
      case 'sports':
        customIcon = Icons.fitness_center_outlined;
        break;
      default:
        customIcon = icon;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = category;
          _categoryController.text = category;
        });
        _fetchDeals();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4CD964).withOpacity(0.2) 
              : Colors.black.withOpacity(0.3),
          // More rectangular shape with rounded corners to match home screen
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CD964) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              customIcon,
              color: isSelected ? const Color(0xFF4CD964) : Colors.grey[400],
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CD964) : Colors.grey[300],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced loading state with animation
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF4CD964),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hunting for the best deals...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for $_category deals in $_countryName',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state with illustration
  Widget _buildEnhancedEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
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
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find Amazing Deals',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Select a category and tap search to discover incredible savings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isDetectingLocation ? null : _fetchDeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                // Rectangular with consistent radius
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Start Hunting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced deals list with better cards
  Widget _buildEnhancedDealsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final deal = _recommendations[index];
        return _buildEnhancedDealCard(deal);
      },
    );
  }

  // Enhanced deal card with better styling
  Widget _buildEnhancedDealCard(Map<String, dynamic> deal) {
    // Extract values safely
    final title = deal['title'] ?? 'No Title';
    final description = deal['description'] ?? 'No Description';
    final url = deal['url'] as String?;
    
    // Handle nested maps safely
    final retailerName = deal['retailer'] is Map 
        ? (deal['retailer']['name'] ?? 'Unknown') 
        : 'Unknown';
        
    // Handle price information safely
    final priceInfo = deal['price'] is Map ? deal['price'] : null;
    final discountPercentage = priceInfo != null 
        ? priceInfo['discountPercentage'] ?? 0 
        : 0;
    
    final discountValue = discountPercentage is int || discountPercentage is double
        ? discountPercentage.toDouble()
        : 0.0;
    
    // Create a badge showing discount level
    Widget? discountBadge;
    if (discountValue > 0) {
      discountBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4CD964),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${discountValue.toInt()}% OFF',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        // Consistent border radius with home screen
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: url != null ? () => _openLink(url) : null,
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with title and retailer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Retailer and discount row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              retailerName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (discountBadge != null) discountBadge,
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Deal Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                
                // Action row with rectangular button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text("View Deal"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xFF4CD964),
                      // More rectangular shape with consistent radius
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: url != null ? () => _openLink(url) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String? url) async {
    if (url == null) return;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunch(uri.toString())) { // Use canLaunch
        await launch(uri.toString(), forceSafariVC: false, forceWebView: false); // Use launch
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

  // Update the showCountryPicker dialog
  void _showCountryPicker() {
    // Create a list of common countries
    final commonCountries = [
      {'code': 'US', 'name': 'United States'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'IT', 'name': 'Italy'},
      {'code': 'ES', 'name': 'Spain'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'JP', 'name': 'Japan'},
      {'code': 'CN', 'name': 'China'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'BR', 'name': 'Brazil'},
      {'code': 'IN', 'name': 'India'},
      {'code': 'TN', 'name': 'Tunisia'},
      {'code': 'MA', 'name': 'Morocco'},
      {'code': 'EG', 'name': 'Egypt'},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Country',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Deals will be searched for this country',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF4CD964)),
                      onPressed: () {
                        Navigator.pop(context); // First close the dialog
                        
                        // Call the new method that forces a refresh
                        _forceRefreshCountry();
                      },
                      tooltip: 'Refresh location',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: commonCountries.length,
                  itemBuilder: (context, index) {
                    final country = commonCountries[index];
                    final isSelected = _detectedCountry == country['code'];
                    
                    return InkWell(
                      onTap: () {
                        _setCountry(country['code']!, country['name']!);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: isSelected ? const Color(0xFF4CD964).withOpacity(0.15) : Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country['name']!,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF4CD964) : Colors.white,
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      country['code']!,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CD964),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CD964),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
