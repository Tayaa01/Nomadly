import 'package:flutter/foundation.dart';
import '../services/tips_service.dart';

class DestinationProvider with ChangeNotifier {
  final TipsService _tipsService = TipsService(); // Create a local instance
  List<String> _availableCountries = [];
  String? _selectedCountry;
  String? _selectedTipCategory;
  bool _hasInitializedCountry = false;
  bool _hasManuallySelectedCountry = false; // Added field
  List<String> _tipCategories = [];
  String? _currencyCode;

  // Cache fields
  List<Map<String, dynamic>> _cachedFlights = [];
  List<Map<String, dynamic>> _cachedHotels = [];
  String? _cachedDataCountry; // For which country the data is cached

  DestinationProvider() {
    _initializeCountries();
  }

  Future<void> _initializeCountries() async {
    try {
      _availableCountries = await _tipsService.getAvailableCountries();
      // Do not automatically select the first country here if we want "Japan" to be the default
      // The default selection will be handled in HomePage or by manual selection.
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
  bool get hasManuallySelectedCountry =>
      _hasManuallySelectedCountry; // Added getter
  List<String> get tipCategories => _tipCategories;
  String? get currencyCode => _currencyCode;

  // Cache getters
  List<Map<String, dynamic>> get cachedFlights => _cachedFlights;
  List<Map<String, dynamic>> get cachedHotels => _cachedHotels;
  String? get cachedDataCountry => _cachedDataCountry;

  // Setters
  void setSelectedCountry(String country) {
    if (_selectedCountry != country) {
      // If country is actually changing
      _clearCache(); // Clear cache for the old country
    }
    if (_availableCountries.contains(country)) {
      _selectedCountry = country;
      _hasManuallySelectedCountry =
          true; // Mark that a country has been deliberately selected
      notifyListeners();
    } else if (country == "Japan" && !_availableCountries.contains("Japan")) {
      // If Japan is forced but not in the list, add it and select it.
      // This is a fallback if Japan isn’t in the fetched countries for some reason.
      _availableCountries.add("Japan");
      _availableCountries.sort(); // Keep it sorted
      _selectedCountry = country;
      _hasManuallySelectedCountry = true;
      notifyListeners();
    }
  }

  void setInitialCountry(String userActualCountry) {
    // This method is for recording the user’s actual country from their profile.
    // It should set _hasInitializedCountry = true.
    // It should NOT override _selectedCountry if it was already set by a manual selection
    // or by the default "Japan" logic in HomePage.
    _hasInitializedCountry =
        true; // Mark that we’ve processed the user’s country from profile.

    // If no country has been selected yet (neither default nor manual),
    // then we can use the user’s actual country as the selected one.
    if (_selectedCountry == null &&
        _availableCountries.contains(userActualCountry)) {
      _selectedCountry = userActualCountry;
    } else if (_selectedCountry == null && _availableCountries.isNotEmpty) {
      // Fallback if userActualCountry is not in availableCountries but _selectedCountry is still null
      final matches =
          _availableCountries
              .where(
                (c) =>
                    c.toLowerCase().contains(userActualCountry.toLowerCase()) ||
                    userActualCountry.toLowerCase().contains(c.toLowerCase()),
              )
              .toList();
      if (matches.isNotEmpty) {
        _selectedCountry = matches.first;
      }
    }
    notifyListeners();
  }

  void setTipCategory(String? category) {
    _selectedTipCategory = category;
    notifyListeners();
  }

  Future<void> loadCategoriesForCountry() async {
    if (_selectedCountry == null) return;

    try {
      _tipCategories = await _tipsService.getCategoriesForCountry(
        _selectedCountry!,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading tip categories: $e');
    }
  }

  void setCurrencyCode(String code) {
    _currencyCode = code;
    notifyListeners();
  }

  // Cache update methods
  void updateCache(
    String country,
    List<Map<String, dynamic>> flights,
    List<Map<String, dynamic>> hotels,
  ) {
    _cachedDataCountry = country;
    _cachedFlights = List.from(
      flights,
    ); // Create copies to avoid modification issues
    _cachedHotels = List.from(hotels);
    print(
      '[DestinationProvider] Cache updated for $country. Flights: ${_cachedFlights.length}, Hotels: ${_cachedHotels.length}',
    );
    notifyListeners();
  }

  void _clearCache() {
    _cachedFlights = [];
    _cachedHotels = [];
    _cachedDataCountry = null;
    print('[DestinationProvider] Cache cleared.');
  }

  void clearCacheForCountry(String country) {
    if (_cachedDataCountry == country) {
      _clearCache();
      notifyListeners();
    }
  }

  // Clear state when needed (like logout)
  void clearState() {
    _selectedCountry = null; // Let HomePage re-apply default "Japan" logic
    _selectedTipCategory = null;
    _hasInitializedCountry = false;
    _hasManuallySelectedCountry = false; // Reset this flag
    _currencyCode = null;
    _clearCache(); // Clear cache on logout or state clear
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
