import 'package:flutter/foundation.dart';
import '../services/tips_service.dart';

class DestinationProvider with ChangeNotifier {
  final TipsService _tipsService = TipsService(); // Create a local instance
  List<String> _availableCountries = [];
  String? _selectedCountry;
  String? _selectedTipCategory;
  bool _hasInitializedCountry = false;
  List<String> _tipCategories = [];
  String? _currencyCode;

  DestinationProvider() {
    _initializeCountries();
  }

  Future<void> _initializeCountries() async {
    try {
      _availableCountries = await _tipsService.getAvailableCountries();
      if (_availableCountries.isNotEmpty && _selectedCountry == null) {
        _selectedCountry = _availableCountries[0];
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing countries: $e');
    }
  }

  // Add this public method to initialize countries if needed
  Future<void> initializeCountriesIfNeeded() async {
    if (_availableCountries.isEmpty) {
      await _initializeCountries();
    }
  }

  // Getters
  List<String> get availableCountries => _availableCountries;
  String? get selectedCountry => _selectedCountry;
  String? get selectedTipCategory => _selectedTipCategory;
  bool get hasInitializedCountry => _hasInitializedCountry;
  List<String> get tipCategories => _tipCategories;
  String? get currencyCode => _currencyCode;

  // Setters
  void setSelectedCountry(String country) {
    if (_availableCountries.contains(country)) {
      _selectedCountry = country;
      notifyListeners();
    }
  }

  void setInitialCountry(String country) {
    if (_availableCountries.contains(country)) {
      _selectedCountry = country;
      _hasInitializedCountry = true;
      notifyListeners();
    } else if (_availableCountries.isNotEmpty) {
      // Try to find a close match
      final matches = _availableCountries.where(
        (c) => c.toLowerCase().contains(country.toLowerCase()) || 
               country.toLowerCase().contains(c.toLowerCase())
      ).toList();
      
      if (matches.isNotEmpty) {
        _selectedCountry = matches.first;
        _hasInitializedCountry = true;
        notifyListeners();
      }
    }
  }

  void setTipCategory(String? category) {
    _selectedTipCategory = category;
    notifyListeners();
  }

  Future<void> loadCategoriesForCountry() async {
    if (_selectedCountry == null) return;
    
    try {
      _tipCategories = await _tipsService.getCategoriesForCountry(_selectedCountry!);
      notifyListeners();
    } catch (e) {
      print('Error loading tip categories: $e');
    }
  }

  void setCurrencyCode(String code) {
    _currencyCode = code;
    notifyListeners();
  }

  // Clear state when needed (like logout)
  void clearState() {
    _selectedCountry = _availableCountries.isNotEmpty ? _availableCountries[0] : null;
    _selectedTipCategory = null;
    _hasInitializedCountry = false;
    _currencyCode = null;
    notifyListeners();
  }

  // Add a new method to search for countries
  List<String> searchCountries(String query) {
    if (query.isEmpty) return [];
    
    return _availableCountries
        .where((country) => country.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}