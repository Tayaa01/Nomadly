import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import '../widgets/custom_bottom_nav.dart'; // REMOVE THIS LINE
import '../providers/destination_provider.dart';
import '../services/deals_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart'; // Add this import
import 'dart:convert';
import 'package:flutter/services.dart';

class DealsScreen extends StatefulWidget {
  final bool isDarkMode;

  const DealsScreen({super.key, required this.isDarkMode});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deals = [];
  String? _errorMessage;
  Map<String, dynamic> _countryImages = {};

  @override
  void initState() {
    super.initState();
    _loadDeals();
    _loadCountryImages();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      final selectedCountry = destinationProvider.selectedCountry;

      // Make sure we have a country selected
      if (selectedCountry == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please select a destination first';
        });
        return;
      }

      // Fetch deals from service
      final deals = await DealsService.fetchDeals(selectedCountry);
      
      if (mounted) {
        setState(() {
          _deals = deals;
          _isLoading = false;
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

  Future<void> _loadCountryImages() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/country_images.json');
      setState(() {
        _countryImages = json.decode(jsonString);
      });
    } catch (e) {
      print('Error loading country images: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Deals'), // Updated title
        // ...existing app bar code...
      ),
      drawer: const AppDrawer(currentRoute: '/deals'), // Add this line
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD964)),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _deals.isEmpty
                  ? _buildEmptyView()
                  : _buildDealsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              onPressed: _loadDeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No deals available at the moment',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or try another destination',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsView() {
    return RefreshIndicator(
      onRefresh: _loadDeals,
      color: const Color(0xFF4CD964),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deals.length,
        itemBuilder: (context, index) {
          final deal = _deals[index];
          return _buildDealCard(
            title: deal['title'] ?? 'Travel Deal',
            description: deal['description'] ?? 'No description available',
            price: deal['price'],
            discount: deal['discount'],
            imageUrl: deal['imageUrl'],
            link: deal['link'],
            index: index, // Pass the index to ensure each deal gets a different image
          );
        },
      ),
    );
  }

  Widget _buildDealCard({
    required String title,
    required String description,
    String? price,
    String? discount,
    String? imageUrl,
    String? link,
    required int index,
  }) {
    // Extract destination from description or title for better image matching
    String destination = '';
    final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
    if (destinationProvider.selectedCountry != null) {
      destination = destinationProvider.selectedCountry!;
    } else {
      // Try to extract destination from description or title
      final combinedText = '$title $description'.toLowerCase();
      
      // List of common destinations to check for
      final destinations = ['paris', 'france', 'italy', 'rome', 'london', 'uk', 'japan', 'tokyo', 'new york', 
                           'spain', 'barcelona', 'australia', 'sydney', 'morocco', 'egypt', 'dubai', 'thailand'];
      
      for (final dest in destinations) {
        if (combinedText.contains(dest)) {
          destination = dest;
          break;
        }
      }
      
      // Default if no destination found
      if (destination.isEmpty) {
        destination = 'travel';
      }
    }
    
    // Get a relevant touristic image for this deal
    final tourismImageUrl = _getDestinationImage(destination, title, index);
    
    // Format price if it exists
    String? formattedPrice = price;
    if (price != null) {
      // Make sure the price has proper formatting if it doesn't already
      if (!price.contains(',') && !price.contains('.')) {
        try {
          // Try to parse as a number and format it
          final numericPrice = int.tryParse(price.replaceAll(RegExp(r'[^\d]'), ''));
          if (numericPrice != null && numericPrice > 999) {
            String currencySymbol = '';
            if (price.contains('\$')) {
              currencySymbol = '\$';
            } else if (price.toLowerCase().contains('usd')) currencySymbol = 'USD ';
            
            formattedPrice = '$currencySymbol${numericPrice.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},'
            )}';
          }
        } catch (e) {
          // Keep original price if formatting fails
          print('Error formatting price: $e');
        }
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLink(link),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal image with improved image loading
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: tourismImageUrl, // Use our new tourism image
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF333333),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CD964),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF333333),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey[600],
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            
            // Deal info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (formattedPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formattedPrice,
                          style: const TextStyle(
                            color: Color(0xFF4CD964),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Discount badge
                  if (discount != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CD964).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Color(0xFF4CD964),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  
                  // Description
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // View deal button
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openLink(link),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CD964),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            formattedPrice != null ? 'Book for $formattedPrice' : 'View Deal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix: Ensure this method always returns a non-null string
  String _getDestinationImage(String destination, String dealTitle, int index) {
    // Normalize destination for lookup
    destination = destination.trim();
    
    // Find matching country in the JSON
    String countryKey = '';
    for (String key in _countryImages.keys) {
      if (key.toLowerCase() == destination.toLowerCase() || 
          destination.toLowerCase().contains(key.toLowerCase())) {
        countryKey = key;
        break;
      }
    }
    
    // If no match was found, use default country
    if (countryKey.isEmpty && _countryImages.isNotEmpty) {
      countryKey = "United States"; // Default to United States if country wasn't found
      
      // Make sure the default country exists in our dataset
      if (!_countryImages.containsKey(countryKey)) {
        // If United States isn't available, use the first country in the dataset
        countryKey = _countryImages.keys.first;
      }
    }
    
    // If we found a matching country with tourism images
    if (countryKey.isNotEmpty && 
        _countryImages.containsKey(countryKey) && 
        _countryImages[countryKey]['tourism'] is List && 
        (_countryImages[countryKey]['tourism'] as List).isNotEmpty) {
      
      // Get tourism images for this country
      final tourismImages = _countryImages[countryKey]['tourism'] as List;
      
      // Use the index to cycle through different tourism images
      final imageIndex = index % tourismImages.length;
      return tourismImages[imageIndex];
    }
    
    // Special image arrays by deal type (original fallback)
    final List<String> foodImages = [
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000',
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000',
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=1000',
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=1000',
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1000',
    ];

    final List<String> activityImages = [
      'https://images.unsplash.com/photo-1530789253388-582c481c54b0?q=80&w=1000',
      'https://images.unsplash.com/photo-1576158114254-e748df57e8fb?q=80&w=1000',
      'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?q=80&w=1000',
      'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=1000',
      'https://images.unsplash.com/photo-1604537466158-719b1972feb8?q=80&w=1000',
    ];

    // Check deal type in title
    final dealTitleLower = dealTitle.toLowerCase();
    
    if (dealTitleLower.contains('food') || 
        dealTitleLower.contains('restaurant') || 
        dealTitleLower.contains('eat') ||
        dealTitleLower.contains('cuisine') ||
        dealTitleLower.contains('dining')) {
      return foodImages[index % foodImages.length];
    } else if (dealTitleLower.contains('activity') || 
               dealTitleLower.contains('tour') || 
               dealTitleLower.contains('adventure') ||
               dealTitleLower.contains('experience')) {
      return activityImages[index % activityImages.length];
    }

    // Final fallback to general tourism images
    final List<String> generalTourismImages = [
      'https://images.unsplash.com/photo-1503220317375-aaad61436b1b?q=80&w=1000',
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=1000',
      'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?q=80&w=1000',
      'https://images.unsplash.com/photo-1500835556837-99ac94a94552?q=80&w=1000',
      'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?q=80&w=1000',
    ];
    
    return generalTourismImages[index % generalTourismImages.length];
  }
}
