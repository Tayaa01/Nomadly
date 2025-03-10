import 'package:flutter/material.dart';
import '../services/deals_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cultural_tips_screen.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  final DealsService _dealsService = DealsService();
  late TabController _tabController;
  late TabController _mainTabController;
  String _selectedCountry = 'global';
  String _selectedCategory = 'travel';
  bool _isLoading = false;
  DealAnalysis? _dealAnalysis;
  String? _error;

  final List<String> _validCategories = [
    'travel',
    'groceries',
    'restaurants',
    'fashion',
    'electronics',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _validCategories.length,
      vsync: this,
    );
    _mainTabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadDeals();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _validCategories[_tabController.index];
      });
      _loadDeals();
    }
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysis = await _dealsService.searchDeals(
        country: _selectedCountry,
        category: _selectedCategory,
      );

      setState(() {
        _dealAnalysis = analysis;
        _isLoading = false;
      });

      if (analysis.recommendations.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${analysis.recommendations.length} deals for you!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load deals: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadDeals,
            textColor: Colors.white,
          ),
        ),
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
        title: const Text(
          'Travel Tips',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: const Color(0xFF4CD964),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4CD964),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.local_offer), text: 'DEALS'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'CULTURAL TIPS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [_buildDealsTab(), const CulturalTipsScreen()],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/currency-converter');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/translation');
            } else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/statistics');
            }
          }
        },
      ),
    );
  }

  Widget _buildDealsTab() {
    return Column(
      children: [
        _buildCategoryTabs(),
        _buildCountrySelector(),
        Expanded(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CD964)),
                  )
                  : _error != null
                  ? _buildErrorView()
                  : _dealAnalysis == null
                  ? _buildEmptyView()
                  : _buildDealsList(),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CD964).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
          border: Border.all(color: const Color(0xFF4CD964), width: 1.5),
        ),
        labelColor: const Color(0xFF4CD964),
        unselectedLabelColor: Colors.grey[400],
        tabs:
            _validCategories
                .map(
                  (category) => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category == 'travel'
                              ? Icons.flight
                              : category == 'groceries'
                              ? Icons.shopping_cart
                              : category == 'restaurants'
                              ? Icons.restaurant
                              : category == 'fashion'
                              ? Icons.shopping_bag
                              : Icons.devices,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(category.toUpperCase()),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCountry,
        decoration: InputDecoration(
          labelText: 'Select Country',
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white),
        items:
            [
              'global',
              'usa',
              'uk',
              'canada',
              'australia',
              'france',
              'germany',
              'italy',
              'spain',
              'japan',
            ].map((country) {
              return DropdownMenuItem(
                value: country,
                child: Text(country.toUpperCase()),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCountry = value;
            });
            _loadDeals();
          }
        },
      ),
    );
  }

  Widget _buildDealsList() {
    return RefreshIndicator(
      onRefresh: _loadDeals,
      color: const Color(0xFF4CD964),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_dealAnalysis!.savingsTips.isNotEmpty) ...[
            _buildSavingsTipsSection(),
            const SizedBox(height: 16),
          ],
          ..._dealAnalysis!.recommendations.map(_buildDealCard).toList(),
        ],
      ),
    );
  }

  Widget _buildSavingsTipsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF4CD964)),
              const SizedBox(width: 8),
              Text(
                'Money-Saving Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_dealAnalysis?.savingsTips ?? []).map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF4CD964),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (deal.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                deal.imageUrl!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  deal.description,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                if (deal.price != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: Color(0xFF4CD964)),
                      const SizedBox(width: 8),
                      Text(
                        '${deal.price!.currency} ${deal.price!.current?.toStringAsFixed(2) ?? "N/A"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (deal.price!.discountPercentage != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD964),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${deal.price!.discountPercentage!.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (deal.promoCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4CD964).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF4CD964),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use code: ${deal.promoCode!.code}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (deal.promoCode!.description.isNotEmpty)
                              Text(
                                deal.promoCode!.description,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Icons.store, color: Color(0xFF4CD964)),
                    const SizedBox(width: 8),
                    Text(
                      deal.retailer.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (deal.retailer.rating != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        deal.retailer.rating!.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(deal.url);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CD964),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Deal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No deals found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the category or country',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading deals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }
}
