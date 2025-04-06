import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/destination_provider.dart';
import '../services/deals_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeals();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Consumer<DestinationProvider>(
          builder: (context, destinationProvider, _) {
            return Text(
              destinationProvider.selectedCountry != null
                  ? 'Deals in ${destinationProvider.selectedCountry}'
                  : 'Travel Deals',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4CD964)),
            onPressed: _loadDeals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD964)),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _deals.isEmpty
                  ? _buildEmptyView()
                  : _buildDealsView(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Ensure this is updated to match the deals index
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
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
  }) {
    // Generate a better fallback image if none provided
    final fallbackImageUrl = imageUrl ?? _generateDynamicImageUrl(title, description);
    
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
            if (price.contains('\$')) currencySymbol = '\$';
            else if (price.toLowerCase().contains('usd')) currencySymbol = 'USD ';
            
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
            // Deal image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: fallbackImageUrl,
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
                errorWidget: (context, url, error) => _buildFallbackImage(title),
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

  // Add these helper methods to the DealsScreen class:

  // Create a more attractive fallback image with text
  Widget _buildFallbackImage(String title) {
    // Use a simplified query without complex terms
    final simpleQuery = 'travel';
    
    return CachedNetworkImage(
      imageUrl: 'https://source.unsplash.com/random/600x400/?$simpleQuery',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFF333333),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: Colors.grey[600], size: 40),
              const SizedBox(height: 8),
              Text(
                'Loading image...',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildLocalFallbackImage(title),
    );
  }
  
  // Fix the _buildLocalFallbackImage method to handle missing assets
  Widget _buildLocalFallbackImage(String title) {
    return Container(
      color: const Color(0xFF333333),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Replace asset loading with a solid color container
          Container(
            color: const Color(0xFF1E1E1E),
            child: Center(
              child: Icon(
                Icons.flight_takeoff,
                color: const Color(0xFF4CD964),
                size: 64,
              ),
            ),
          ),
          // Gradient overlay to ensure text is readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Text overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              title.length > 30 ? '${title.substring(0, 30)}...' : title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Fix the array declaration in _generateDynamicImageUrl method
  String _generateDynamicImageUrl(String title, String description) {
    // Simplify the query to just use travel-related terms
    final List<String> travelTerms = [
      'travel', 'vacation', 'tour', 'journey', 'destination'
    ];
    
    // Pick a random travel term
    final randomTerm = travelTerms[DateTime.now().millisecond % travelTerms.length];
    
    // Use a more reliable format
    return 'https://source.unsplash.com/random/600x400/?$randomTerm';
  }
}
