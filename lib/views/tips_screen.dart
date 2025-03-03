import 'package:flutter/material.dart';
import '../models/tip.dart';
import '../services/deals_service.dart';
import 'dart:ui';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/deal_map_view.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _specificController = TextEditingController();
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

  // Updated build method for better vertical space usage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Travel Tips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20, // Slightly larger
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CD964),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedCountry,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13, // Slightly larger
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.language,
              color: Color(0xFF4CD964),
              size: 24, // Slightly larger
            ),
            onPressed: () => _showCountrySelector(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56), // Taller to give more space
          child: _buildTabBar(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTipsTab(), _buildDealsTab()],
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

  // More compact and efficient tab bar
  Widget _buildTabBar() {
    return Container(
      height: 48, // Slightly larger for better tappability
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
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
          border: Border.all(
            color: const Color(0xFF4CD964),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        labelColor: const Color(0xFF4CD964),
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15, // Slightly larger
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 15, // Slightly larger
        ),
        tabs: [
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tips_and_updates, size: 18),
                const SizedBox(width: 8),
                const Text('Travel Tips'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer, size: 18),
                const SizedBox(width: 8),
                const Text('Deals'),
              ],
            ),
          ),
        ],
        onTap: (index) {
          if (index == 1 && _dealAnalysis == null) {
            _loadDeals();
          }
        },
      ),
    );
  }

  // More compact category selector
  Widget _buildCategorySelector() {
    return Container(
      height: 48, // Slightly taller
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadTips();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                  ? const Color(0xFF4CD964)
                  : const Color(0xFF333333),
                foregroundColor: isSelected ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 40),
                elevation: isSelected ? 1 : 0,
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14, // Slightly larger
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Optimized tips tab to maximize content area
  Widget _buildTipsTab() {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child: _isLoadingTips
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CD964)),
              )
            : _tips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'No tips available for $_selectedCategory\nin $_selectedCountry',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _buildTipsList(),
        ),
      ],
    );
  }

  // More space-efficient tip cards
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16), // More space between cards
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Increased padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22), // Slightly larger icon
            ),
            const SizedBox(width: 16), // More space between icon and content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tip.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 16, // Larger
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedCountry,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // More space before content
                  Text(
                    tip.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15, // Slightly larger for readability
                      height: 1.5, // Better line spacing
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

  Widget _buildDealsTab() {
    return Column(
      children: [
        _buildDealSearch(),
        Expanded(
          child: _isLoadingDeals
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
                              color: const Color(0xFF333333),
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CD964).withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter any category (e.g., food, electronics)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.category, color: Color(0xFF4CD964)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CD964).withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _specificController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Specific requirements (optional)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CD964)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadDeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
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
            'Search for deals in $_selectedCountry',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (deal.discount != null) ...[
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
                      deal.discount!,
                      style: const TextStyle(
                        color: Color(0xFF4CD964),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  deal.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Reason
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber[400],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deal.reason,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (deal.url != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _launchDealUrl(deal.url!),
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

  Widget _buildTipsList() {
    return ListView.builder(
      padding: EdgeInsets.zero, // Remove padding since we handle it in the cards
      itemCount: _tips.length,
      itemBuilder: (context, index) {
        final tip = _tips[index];
        return _buildTipCard(tip, index);
      },
    );
  }


  Future<void> _launchDealUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }



  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.public, color: Color(0xFF4CD964)),
                  const SizedBox(width: 12),
                  const Text(
                    'Select a Country',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[800], height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _availableCountries.length,
                itemBuilder: (context, index) {
                  final country = _availableCountries[index];
                  final isSelected = country == _selectedCountry;
                  
                  return ListTile(
                    title: Text(
                      country,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF4CD964) : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Color(0xFF4CD964))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      _loadCategories();
                      _loadTips();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
