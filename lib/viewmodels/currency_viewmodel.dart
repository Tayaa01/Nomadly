import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/currency_service.dart';
<<<<<<< HEAD
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Uncomment this import
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyViewModel extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
=======

class CurrencyViewModel extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  String? sourceCountry;
  String? targetCountry;
>>>>>>> aziz
  String? scannedAmount;
  double? convertedAmount;
  String? convertedCurrencySymbol;
  bool isTaxRefundAvailable = false;
  String? taxRefundMessage;
  List<String> taxRefundTips = [];
  bool isConverting = false;
  bool isImageProcessing = false;
<<<<<<< HEAD
  bool isLoadingLocation = false;
=======
>>>>>>> aziz
  bool showTips = false;
  XFile? selectedImage;
  String? errorMessage;
  String? sourceCountryName;
<<<<<<< HEAD
  String? currentCountryCode;
=======
>>>>>>> aziz
  String? targetCountryName;
  double? taxRefundAmount;
  String? taxRefundCurrency;
  List<String> taxRefundRequirements = [];
  String? taxRefundInstructions;
  double? convertedMinAmount;
  String? convertedMinCurrency;

  final TextEditingController amountController = TextEditingController();

<<<<<<< HEAD
  // Keys for storing preferences
  static const String COUNTRY_CODE_KEY = 'country_code';
  static const String COUNTRY_NAME_KEY = 'country_name';

  CurrencyViewModel() {
    // Load saved country or get user's location
    _loadSavedCountry();
  }
  
  // Load the saved country from SharedPreferences
  Future<void> _loadSavedCountry() async {
    try {
      isLoadingLocation = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString(COUNTRY_CODE_KEY);
      final savedCountryName = prefs.getString(COUNTRY_NAME_KEY);
      
      if (savedCountryCode != null && savedCountryName != null) {
        // Use saved values
        currentCountryCode = savedCountryCode;
        sourceCountryName = savedCountryName;
        print('Loaded saved country: $sourceCountryName ($currentCountryCode)');
      } else {
        // Try to detect location
        await getUserLocation();
      }
    } catch (e) {
      print('Error loading saved country: $e');
      // Set default values on error
      currentCountryCode = 'US';
      sourceCountryName = 'United States';
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Get user's current location and determine country
  Future<void> getUserLocation() async {
    isLoadingLocation = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = "Location permission denied. Cannot determine your country.";
          _setDefaultCountry();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        errorMessage = "Location permission permanently denied. Please enable it in settings.";
        _setDefaultCountry();
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium
      );
      
      print('Got location: ${position.latitude}, ${position.longitude}');
      
      try {
        // Use reverse geocoding to get country
        final placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude,
          localeIdentifier: 'en_US'  // Ensure English locale for consistent results
        );
        
        print('Received ${placemarks.length} placemarks');
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          print('Placemark data: ${placemark.toJson()}');
          
          if (placemark.isoCountryCode != null && placemark.country != null) {
            currentCountryCode = placemark.isoCountryCode;
            sourceCountryName = placemark.country;
            print('Detected country: $sourceCountryName ($currentCountryCode)');
            
            // Save the detected country
            await setCountry(currentCountryCode!, sourceCountryName!);
          } else {
            print('Could not extract country code or name from placemark');
            _setDefaultCountry();
          }
        } else {
          print('No placemarks returned');
          _setDefaultCountry();
        }
      } catch (e) {
        print('Error with geocoding: $e');
        _setDefaultCountry();
      }
    } catch (e) {
      print('Error getting location: $e');
      errorMessage = "Could not determine your location. Please check your settings.";
      _setDefaultCountry();
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }
  
  // Helper to set a default country when detection fails
  void _setDefaultCountry() {
    currentCountryCode = 'US';
    sourceCountryName = 'United States';
    print('Using default country: $sourceCountryName ($currentCountryCode)');
  }

  // Set country method - also saves to SharedPreferences
  Future<void> setCountry(String countryCode, String countryName) async {
    currentCountryCode = countryCode;
    sourceCountryName = countryName;
    print('Setting country: $sourceCountryName ($currentCountryCode)');
    
    // Save the selection for future app launches
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(COUNTRY_CODE_KEY, countryCode);
      await prefs.setString(COUNTRY_NAME_KEY, countryName);
      print('Saved country preferences');
    } catch (e) {
      print('Error saving country preferences: $e');
    }
    
    notifyListeners();
=======
  CurrencyViewModel() {
    // No need to fetch currencies
>>>>>>> aziz
  }

  Future<void> takePhoto() async {
    try {
      isImageProcessing = true;
      notifyListeners();

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        selectedImage = photo;
        amountController.clear();
        print('Photo taken: ${photo.path}');
      }
    } catch (e) {
      print('Error taking photo: $e');
<<<<<<< HEAD
      errorMessage = "Error capturing image: $e";
=======
>>>>>>> aziz
    } finally {
      isImageProcessing = false;
      notifyListeners();
    }
  }

  Future<void> convertCurrency() async {
<<<<<<< HEAD
    isConverting = true;
    clearState();  
=======
    if (targetCountry == null || sourceCountry == null) {
      print('Source or target country not selected');
      errorMessage = "Please select both countries";
      notifyListeners();
      return;
    }

    isConverting = true;
    clearState();  // Only clear conversion-related state
>>>>>>> aziz
    notifyListeners();

    try {
      if (selectedImage != null) {
        print('Converting currency with image: ${selectedImage!.path}');
        final data = await _currencyService.analyzeAndConvertImage(
          selectedImage!,
<<<<<<< HEAD
          countryCode: currentCountryCode, // Pass the detected country code
=======
          sourceCountry!,
          targetCountry!,
>>>>>>> aziz
        );

        print('API response: $data');

        // Handle bill data
        if (data['bill'] != null) {
          final bill = data['bill'];
          final amount = bill['amount'];
          final converted = bill['convertedAmount'];
          
          scannedAmount = '${amount['value']} ${amount['currency']}';
          sourceCountryName = bill['country'];
          convertedAmount = double.tryParse(converted['value'].toString());
          convertedCurrencySymbol = converted['currency'];
          targetCountryName = converted['country'];
          
          print('Processed bill data: $scannedAmount, $convertedAmount $convertedCurrencySymbol');
        }

        // Handle tax refund data
        if (data['taxRefund'] != null) {
          final taxRefund = data['taxRefund'];
          isTaxRefundAvailable = taxRefund['available'] ?? false;
          showTips = true;  // Always show tips section
          
          print('Tax refund available: $isTaxRefundAvailable');
          
          if (isTaxRefundAvailable) {
            // Handle refund amount
            if (taxRefund['amount'] != null) {
              final refundAmount = taxRefund['amount'];
              taxRefundAmount = double.tryParse(refundAmount['value'].toString());
              taxRefundCurrency = refundAmount['currency'];
              print('Set refund amount: $taxRefundAmount $taxRefundCurrency');
            }
            
            // Handle instructions
            taxRefundInstructions = taxRefund['instructions']?.toString();
            print('Set instructions: $taxRefundInstructions');
            
            // Handle requirements
            if (taxRefund['requirements'] != null) {
              taxRefundRequirements = List<String>.from(taxRefund['requirements']);
              print('Set requirements: $taxRefundRequirements');
            }

            // Clear any previous error message
            taxRefundMessage = null;
          } else {
            // Handle unavailable tax refund
            taxRefundAmount = null;
            taxRefundCurrency = null;
            taxRefundRequirements = [];
            taxRefundInstructions = null;
            
            taxRefundMessage = taxRefund['message'];
            print('Set tax refund message: $taxRefundMessage');
            
            if (taxRefund['convertedMinAmount'] != null) {
              final minAmount = taxRefund['convertedMinAmount'];
              convertedMinAmount = double.tryParse(minAmount['value']?.toString() ?? '');
              convertedMinCurrency = minAmount['currency'];
              print('Set minimum amount: $convertedMinAmount $convertedMinCurrency');
            }
          }
        }
        
<<<<<<< HEAD
        notifyListeners();
=======
        notifyListeners();  // Notify after all data is set
>>>>>>> aziz
      } else {
        errorMessage = "Please take a photo first";
        notifyListeners();
      }
    } catch (e) {
      print('Error during conversion: $e');
      errorMessage = "Error converting currency: $e";
      notifyListeners();
    } finally {
      print('Final state - showTips: $showTips, isTaxRefundAvailable: $isTaxRefundAvailable');
      print('Requirements: $taxRefundRequirements');
      print('Instructions: $taxRefundInstructions');
      isConverting = false;
      notifyListeners();
    }
  }

  void clearState() {
<<<<<<< HEAD
    errorMessage = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
=======
    // Only clear necessary state, keeping tax refund info
    errorMessage = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
    
    // Don't reset these immediately
    // isTaxRefundAvailable = false;
    // taxRefundMessage = null;
    // showTips = false;
    // taxRefundAmount = null;
    // taxRefundCurrency = null;
    // taxRefundRequirements = [];
    // taxRefundInstructions = null;
    
    // These can be cleared
>>>>>>> aziz
    convertedMinAmount = null;
    convertedMinCurrency = null;
  }

  void resetAll() {
    selectedImage = null;
    scannedAmount = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
    amountController.clear();
    isTaxRefundAvailable = false;
    taxRefundMessage = null;
    taxRefundTips = [];
    showTips = false;
    notifyListeners();
  }
}
<<<<<<< HEAD

// Add this extension to help with debugging
extension PlacemarkExtension on Placemark {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'street': street,
      'locality': locality,
      'administrativeArea': administrativeArea,
      'country': country,
      'isoCountryCode': isoCountryCode,
      'postalCode': postalCode,
    };
  }
}
=======
>>>>>>> aziz
