import 'package:flutter/material.dart';
import 'package:nomadly/models/tip.dart';
import 'package:nomadly/services/deals_service.dart';
import 'dart:ui';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../widgets/custom_bottom_nav.dart';
import '../widgets/deal_map_view.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCountry = 'Japan';
  String _selectedCategory = 'Dining';
  List<String> _availableCountries = [];
  List<String> _availableCategories = [];
  List<Tip> _tips = [];
  bool _isLoadingTips = true;

  // For deals section
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _specificController = TextEditingController();
  bool _isLoadingDeals = false;
  DealAnalysis? _dealAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCountries();
    _loadTips();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _specificController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await TipsService.getAvailableCountries();
    setState(() {
      _availableCountries = countries;
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await TipsService.getCategoriesForCountry(
      _selectedCountry,
    );
    setState(() {
      _availableCategories = categories;
      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = categories.first;
      }
    });
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoadingTips = true;
    });

    final tips = await TipsService.getTipsByCountryAndCategory(
      _selectedCountry,
      _selectedCategory,
    );

    setState(() {
      _tips = tips;
      _isLoadingTips = false;
    });
  }

  Future<void> _loadDeals() async {
    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a category')));
      return;
    }

    setState(() {
      _isLoadingDeals = true;
    });

    try {
      final dealsService = DealsService();
      final analysis = await dealsService.searchDeals(
        country: _selectedCountry,
        category: _categoryController.text.trim(),
        specific: _specificController.text.trim(),
      );

      setState(() {
        _dealAnalysis = analysis;
        _isLoadingDeals = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDeals = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load deals: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTipsTab(), _buildDealsTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            // If not current tab
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/currency-converter');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/translation');
            }
            else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/planner');
            }
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Smart',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const Text(
                  'Tips & Deals 💡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150, // Fixed width for the dropdown
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  dropdownColor: Colors.grey[800],
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountry = newValue;
                      });
                      _loadCategories();
                      _loadTips();
                      if (_tabController.index == 1) {
                        _loadDeals();
                      }
                    }
                  },
                  items: () {
                    final sortedCountries = List<String>.from(
                      _availableCountries,
                    );
                    sortedCountries.sort();
                    return sortedCountries.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList();
                  }(),
                  isExpanded: true,
                  menuMaxHeight: 300,
                  enableFeedback: true,
                  autofocus: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: const Color(0xFF4CD964),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(icon: Icon(Icons.tips_and_updates), text: 'Travel Tips'),
          Tab(icon: Icon(Icons.local_offer), text: 'Deals'),
        ],
        onTap: (index) {
          if (index == 1 && _dealAnalysis == null) {
            _loadDeals();
          }
        },
      ),
    );
  }

  Widget _buildTipsTab() {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child:
              _isLoadingTips
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CD964)),
                  )
                  : _tips.isEmpty
                  ? Center(
                    child: Text(
                      'No tips available for $_selectedCategory in $_selectedCountry',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                  : _buildTipsList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _loadTips();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4CD964) : Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tips.length,
      itemBuilder: (context, index) {
        final tip = _tips[index];
        return _buildTipCard(tip, index);
      },
    );
  }

  Widget _buildTipCard(Tip tip, int index) {
    final icons = {
      'Dining': Icons.restaurant,
      'Social Interactions': Icons.people,
      'Business': Icons.business,
      'Gifts': Icons.card_giftcard,
      'Language': Icons.translate,
      'Religious Customs': Icons.temple_buddhist,
      'Social Customs': Icons.diversity_3,
      'Social Etiquette': Icons.thumb_up,
      'Ramadan': Icons.nightlight,
      'Gender Considerations': Icons.wc,
      'Numbers': Icons.numbers,
    };

    final icon = icons[tip.category] ?? Icons.lightbulb_outline;
    final colors = [
      const Color(0xFF4CD964),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF2D55),
      const Color(0xFF5856D6),
      const Color(0xFFFF9500),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), Colors.grey[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDealsTab() {
    return Column(
      children: [
        _buildDealSearch(),
        Expanded(
          child:
              _isLoadingDeals
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CD964)),
                  )
                  : _dealAnalysis == null
                  ? _buildInitialDealsState()
                  : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xFF4CD964),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.white,
                            tabs: const [
                              Tab(icon: Icon(Icons.list), text: 'List'),
                              Tab(icon: Icon(Icons.map), text: 'Map'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildDealsContent(),
                              if (_dealAnalysis?.recommendations.isEmpty ??
                                  true)
                                Center(
                                  child: Text(
                                    'No deals found for ${_categoryController.text} in $_selectedCountry',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              else
                                DealMapView(
                                  key: ValueKey(
                                    '${_selectedCountry}_${_categoryController.text}',
                                  ),
                                  deals: _dealAnalysis!.recommendations,
                                  country: _selectedCountry,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildDealSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Category Search Field - now accepts any input
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter any category (e.g., food, electronics, books)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.category, color: Colors.white),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Specific Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _specificController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Specific requirements (optional)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadDeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Search Deals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialDealsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Search for deals in ${_selectedCountry}',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a category to get started',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsContent() {
    final recommendations = _dealAnalysis?.recommendations ?? [];

    if (recommendations.isEmpty) {
      return Center(
        child: Text(
          'No deals found for ${_categoryController.text} in $_selectedCountry',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final deal = recommendations[index];
        return _buildDealCard(deal);
      },
    );
  }

  Widget _buildDealCard(Deal deal) {
    final verified = deal.metadata.verified;
    final popularity = deal.metadata.popularity ?? 0;
    final source = deal.metadata.source;
    final dealType = deal.dealDetails.dealType ?? 'standard';
    final promoCode = deal.dealDetails.promoCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              verified
                  ? const Color(0xFF4CD964).withOpacity(0.3)
                  : Colors.grey[800]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with popularity and verification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (verified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.verified,
                          color: Color(0xFF4CD964),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF4CD964),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${popularity.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Deal content
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
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Deal type and source
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDealTypeColor(dealType).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getDealTypeIcon(dealType),
                            color: _getDealTypeColor(dealType),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDealType(dealType),
                            style: TextStyle(
                              color: _getDealTypeColor(dealType),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      source,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (promoCode != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4CD964).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PROMO CODE',
                          style: TextStyle(
                            color: Color(0xFF4CD964),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promoCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _launchDealUrl(deal.url),
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

  Color _getDealTypeColor(String dealType) {
    switch (dealType) {
      case 'promo_code':
        return const Color(0xFF4CD964);
      case 'bundle':
        return const Color(0xFF5AC8FA);
      case 'sale':
        return const Color(0xFFFF2D55);
      case 'flash_deal':
        return const Color(0xFFFF9500);
      case 'seasonal':
        return const Color(0xFF5856D6);
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchDealUrl(String url) async {
    // Implement URL launching logic here
    // You might want to use url_launcher package
    print('Launching URL: $url');
  }

  IconData _getDealTypeIcon(String dealType) {
    switch (dealType) {
      case 'promo_code':
        return Icons.confirmation_number_outlined;
      case 'bundle':
        return Icons.inventory_2_outlined;
      case 'sale':
        return Icons.sell_outlined;
      case 'flash_deal':
        return Icons.flash_on_outlined;
      case 'seasonal':
        return Icons.event_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  String _formatDealType(String dealType) {
    if (dealType == null) return 'Standard Deal';

    final formatted = dealType.replaceAll('_', ' ');
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }
}
