import 'package:flutter/material.dart';
import '../models/tip.dart';
import '../providers/destination_provider.dart';
import '../services/tips_service.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  final TipsService _tipsService = TipsService();
  bool _isLoading = true;
  List<String> _categories = [];
  List<Tip> _tips = [];
  String? _selectedCategory;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadTipsData();
  }

  @override
  void dispose() {
    if (_categories.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTipsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      final selectedCountry = destinationProvider.selectedCountry;
      final selectedCategory = destinationProvider.selectedTipCategory;

      if (selectedCountry == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please select a destination first';
        });
        return;
      }

      // Load categories for the selected country
      _categories = await _tipsService.getCategoriesForCountry(selectedCountry);
      
      if (_categories.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No tip categories available for $selectedCountry';
        });
        return;
      }
      
      // Initialize tab controller after getting categories
      _tabController = TabController(
        length: _categories.length,
        vsync: this,
        initialIndex: selectedCategory != null && _categories.contains(selectedCategory) 
            ? _categories.indexOf(selectedCategory) 
            : 0,
      );
      
      _tabController.addListener(_handleTabChange);

      // Set selected category
      _selectedCategory = selectedCategory ?? _categories[0];

      // Load tips for the selected category
      if (_selectedCategory != null) {
        _tips = await _tipsService.getTipsByCountryAndCategory(
          selectedCountry,
          _selectedCategory!,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load tips: $e';
        });
      }
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {
        _selectedCategory = _categories[_tabController.index];
      });
      _loadTipsForCategory();
    }
  }

  Future<void> _loadTipsForCategory() async {
    if (_selectedCategory == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _tips = [];
    });

    try {
      final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
      final selectedCountry = destinationProvider.selectedCountry;

      if (selectedCountry != null) {
        final tips = await _tipsService.getTipsByCountryAndCategory(
          selectedCountry,
          _selectedCategory!,
        );

        if (mounted) {
          setState(() {
            _tips = tips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load tips: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationProvider = Provider.of<DestinationProvider>(context);
    final selectedCountry = destinationProvider.selectedCountry;

    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Tips${selectedCountry != null ? ' - $selectedCountry' : ''}'),
        bottom: _categories.isNotEmpty ? TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
          indicatorColor: const Color(0xFF4CD964),
          labelColor: const Color(0xFF4CD964),
          unselectedLabelColor: Colors.grey,
        ) : null,
      ),
      drawer: const AppDrawer(currentRoute: '/tips'),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CD964)))
          : _errorMessage != null 
              ? _buildErrorView() 
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_categories.isEmpty) {
      return _buildEmptyView('No tip categories available for this destination');
    }
    
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        return _buildTipsView();
      }).toList(),
    );
  }

  Widget _buildTipsView() {
    if (_tips.isEmpty) {
      return _buildEmptyView('No tips available for this category');
    }

    return RefreshIndicator(
      onRefresh: _loadTipsForCategory,
      color: const Color(0xFF4CD964),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return _buildTipCard(tip);
        },
      ),
    );
  }

  Widget _buildTipCard(Tip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CD964).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4CD964).withOpacity(0.5),
                ),
              ),
              child: Text(
                tip.category,
                style: const TextStyle(
                  color: Color(0xFF4CD964),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tip.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (tip.country.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF4CD964),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'For trips to ${tip.country}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
              onPressed: _loadTipsData,
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

  Widget _buildEmptyView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
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
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
