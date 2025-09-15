import 'package:flutter/material.dart';
import '../services/cultural_tips_service.dart';

class CulturalTipsScreen extends StatefulWidget {
  const CulturalTipsScreen({super.key});

  @override
  State<CulturalTipsScreen> createState() => _CulturalTipsScreenState();
}

class _CulturalTipsScreenState extends State<CulturalTipsScreen> {
  String _selectedCountry = 'Japan';
  String? _selectedCategory;
  bool _isLoading = true;
  List<String> _availableCountries = [];
  List<String> _categoriesForCountry = [];
  List<CulturalTip> _tips = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load available countries
      final countries = await CulturalTipsService.getAvailableCountries();

      if (countries.isEmpty) {
        setState(() {
          _error = 'No countries available';
          _isLoading = false;
        });
        return;
      }

      _availableCountries = countries;

      // If selected country is not in the list, use the first one
      if (!_availableCountries.contains(_selectedCountry)) {
        _selectedCountry = _availableCountries.first;
      }

      // Load categories for selected country
      final categories = await CulturalTipsService.getCategoriesForCountry(
        _selectedCountry,
      );
      _categoriesForCountry = categories;

      // If no category is selected or the selected category is not available, select the first one
      if (_selectedCategory == null ||
          !_categoriesForCountry.contains(_selectedCategory)) {
        _selectedCategory =
            _categoriesForCountry.isNotEmpty
                ? _categoriesForCountry.first
                : null;
      }

      // Load tips for selected country and category
      if (_selectedCategory != null) {
        _tips = await CulturalTipsService.getTipsByCountryAndCategory(
          _selectedCountry,
          _selectedCategory!,
        );
      } else {
        _tips = await CulturalTipsService.getAllTipsForCountry(
          _selectedCountry,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onCountryChanged(String? country) {
    if (country != null && country != _selectedCountry) {
      setState(() {
        _selectedCountry = country;
        _selectedCategory = null;
      });
      _loadData();
    }
  }

  void _onCategoryChanged(String? category) {
    if (category != null && category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCountrySelector(),
        _buildCategorySelector(),
        Expanded(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CD964)),
                  )
                  : _error != null
                  ? _buildErrorView()
                  : _tips.isEmpty
                  ? _buildEmptyView()
                  : _buildTipsList(),
        ),
      ],
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
            _availableCountries.map((country) {
              return DropdownMenuItem(value: country, child: Text(country));
            }).toList(),
        onChanged: _onCountryChanged,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child:
          _categoriesForCountry.isEmpty
              ? const Center(
                child: Text(
                  'No categories available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoriesForCountry.length,
                itemBuilder: (context, index) {
                  final category = _categoriesForCountry[index];
                  final isSelected = category == _selectedCategory;

                  return GestureDetector(
                    onTap: () => _onCategoryChanged(category),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF4CD964)
                                : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF4CD964)
                                  : Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildTipsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
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

  Widget _buildTipCard(CulturalTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(tip.category),
                  color: const Color(0xFF4CD964),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  tip.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CD964),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip.tip,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dining':
        return Icons.restaurant;
      case 'social interactions':
      case 'social customs':
      case 'social etiquette':
        return Icons.people;
      case 'business':
        return Icons.business;
      case 'gifts':
        return Icons.card_giftcard;
      case 'religious customs':
        return Icons.church;
      case 'language':
        return Icons.translate;
      case 'gender considerations':
        return Icons.wc;
      case 'numbers':
        return Icons.format_list_numbered;
      case 'ramadan':
        return Icons.nightlight;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'No tips available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different country or category',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading tips',
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
}
