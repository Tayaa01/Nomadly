import 'dart:convert';
import 'package:flutter/services.dart';

class CountryCurrencyUtil {
  static Map<String, String>? _countryToCurrency;

  // Initialize the country-currency mapping from the JSON file
  static Future<void> initialize() async {
    if (_countryToCurrency != null) return;

    try {
      final jsonString = await rootBundle.loadString(
        'lib/utils/country-currency.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _countryToCurrency = Map<String, String>.from(jsonMap);
      print(
        'Country-Currency mapping initialized with ${_countryToCurrency!.length} entries',
      );
    } catch (e) {
      print('Error loading country-currency mapping: $e');
      _countryToCurrency = {};
    }
  }

  // Get the currency for a given country code
  static String? getCurrencyForCountry(String countryCode) {
    if (_countryToCurrency == null) {
      print('Warning: Country-Currency mapping not initialized');
      return null;
    }

    final currency = _countryToCurrency![countryCode.toUpperCase()];
    print('Currency for $countryCode: $currency');
    return currency;
  }
}
