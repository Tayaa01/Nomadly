import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomadly/utils/country_currency_util.dart';
import '../services/currency_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Uncomment this import
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Update these imports to include the auth service for getting user preferences
import '../services/transaction_service.dart'; // Add this import
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CurrencyViewModel extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  final AuthService _authService = AuthService();
  final TransactionService _transactionService =
      TransactionService(); // Add this line
  String? scannedAmount;
  double? convertedAmount;
  String? convertedCurrencySymbol;
  bool isTaxRefundAvailable = false;
  String? taxRefundMessage;
  List<String> taxRefundTips = [];
  bool isConverting = false;
  bool isImageProcessing = false;
  bool isLoadingLocation = false;
  bool showTips = false;
  XFile? selectedImage;
  String? errorMessage;
  String? sourceCountryName;
  String? currentCountryCode;
  String? targetCountryName;
  double? taxRefundAmount;
  String? taxRefundCurrency;
  List<String> taxRefundRequirements = [];
  String? taxRefundInstructions;
  double? convertedMinAmount;
  String? convertedMinCurrency;

  final TextEditingController amountController = TextEditingController();

  // Keys for storing preferences
  static const String COUNTRY_CODE_KEY = 'country_code';
  static const String COUNTRY_NAME_KEY = 'country_name';

  // Add these properties to store scan results
  XFile? _scannedImage;
  Map<String, dynamic>? _scanResults;
  bool _isScanning = false;
  bool _hasScannedResults = false;

  // Add this property near the other boolean properties
  bool _showSuccessMessage = false;

  // Getters
  XFile? get scannedImage => _scannedImage;
  Map<String, dynamic>? get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get hasScannedResults => _hasScannedResults;
  bool get showSuccessMessage => _showSuccessMessage;

  // Add this getter for loading state
  bool get isLoading => isScanning || isConverting || isLoadingLocation;

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
  Future<void> getUserLocation({bool forceRefresh = false}) async {
    try {
      // Set isLoadingLocation to true
      isLoadingLocation = true;
      notifyListeners();

      // Skip loading from preferences if forceRefresh is true
      if (!forceRefresh) {
        // Check if we have a saved country from preferences
        final prefs = await SharedPreferences.getInstance();
        final savedCountryCode = prefs.getString('country_code');
        final savedCountryName = prefs.getString('country_name');

        if (savedCountryCode != null && savedCountryName != null) {
          print('Loaded saved country: $savedCountryName ($savedCountryCode)');
          currentCountryCode = savedCountryCode;
          sourceCountryName = savedCountryName;
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage =
              "Location permission denied. Cannot determine your country.";
          _setDefaultCountry();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            "Location permission permanently denied. Please enable it in settings.";
        _setDefaultCountry();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      print('Got location: ${position.latitude}, ${position.longitude}');

      try {
        // Use reverse geocoding to get country
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          localeIdentifier:
              'en_US', // Ensure English locale for consistent results
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
      errorMessage =
          "Could not determine your location. Please check your settings.";
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
  }

  // Method to scan and show results without adding transaction
  Future<void> scanForPreview() async {
    if (_isScanning) return;

    _isScanning = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Take a photo using image picker
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Compress the image before upload
      final XFile? compressed = await compressImage(photo);
      if (compressed == null) {
        errorMessage = 'Failed to compress image.';
        _isScanning = false;
        notifyListeners();
        return;
      }
      _scannedImage = compressed;

      // Get user country for target currency
      final user = await _authService.getCurrentUser();
      final userCountryCode = user?.countryCode ?? 'TN';

      // Source currency based on current country
      final sourceCurrency =
          CountryCurrencyUtil.getCurrencyForCountry(
            currentCountryCode ?? 'US',
          ) ??
          'USD';
      final targetCurrency =
          CountryCurrencyUtil.getCurrencyForCountry(userCountryCode) ?? 'TND';

      print('Currency for ${currentCountryCode}: $sourceCurrency');
      print('Currency for $userCountryCode: $targetCurrency');
      print(
        'Scanning with sourceCurrency: $sourceCurrency, targetCurrency: $targetCurrency',
      );

      // Call new endpoint to analyze and convert
      final result = await _currencyService.analyzeAndConvertImage(
        compressed,
        sourceCurrency: sourceCurrency,
        targetCurrency: targetCurrency,
      );

      print('RECEIVED RESULT TYPE: ${result.runtimeType}');
      print('RECEIVED RESULT: $result');

      // IMPORTANT: Store the scan results safely
      try {
        _scanResults = Map<String, dynamic>.from(result);
      } catch (e) {
        print('ERROR copying result: $e');
        _scanResults = result; // Use original if copy fails
      }

      // ISOLATE all the data extraction and UI updates in a single try block
      try {
        // Extract from imageAnalysis
        final Map<String, dynamic>? imageAnalysis = result['imageAnalysis'];
        final double? detectedAmount = imageAnalysis?['detectedAmount'];

        // Extract from conversionResult
        final Map<String, dynamic>? conversionResult =
            result['conversionResult'];
        final String? toCurrency = conversionResult?['to'];
        final double? resultAmount = conversionResult?['result']?.toDouble();

        // Set UI values in one atomic operation
        final localDisplayCurrency =
            sourceCurrency;

        // Update the state all at once at the end
        amountController.text = detectedAmount?.toString() ?? '';
        scannedAmount =
            detectedAmount != null
                ? '$detectedAmount $localDisplayCurrency'
                : null;
        convertedAmount = resultAmount;
        convertedCurrencySymbol = toCurrency;
        _hasScannedResults = true;

        print(
          'UI update complete: amount=$detectedAmount, currency=$localDisplayCurrency, converted=$resultAmount $toCurrency',
        );
      } catch (e) {
        print('CRITICAL ERROR processing data: $e');
        errorMessage = 'Error displaying results: ${e.toString()}';
        _hasScannedResults = false;
      } finally {
        // Always end the scanning state, regardless of success or error
        _isScanning = false;
        // Notify listeners once at the end
        notifyListeners();
      }
    } catch (e) {
      print('ERROR in scan process: $e');
      errorMessage = 'Failed to scan: ${e.toString()}';
      _isScanning = false;
      notifyListeners();
    }
  }

  // Method to add transaction using previously scanned image
  Future<void> addTransaction() async {
    if (_scannedImage == null || isConverting) return;

    isConverting = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Make sure we have scan results
      if (_scanResults == null) {
        errorMessage = 'No scan results available. Please scan again.';
        isConverting = false;
        notifyListeners();
        return;
      }

      print('Adding transaction from scan results: $_scanResults');

      try {
        // Use the TransactionService method that properly handles scan results
        final transaction = await _transactionService.addTransactionFromScan(
          _scanResults!,
        );

        print('Transaction added successfully: ${transaction.id}');

        // Show success message
        _showSuccessMessage = true;
        isConverting = false;
        _hasScannedResults = false;
        _scanResults = null;
        _scannedImage = null;
        notifyListeners();

        // Hide success message after a few seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_showSuccessMessage) {
            _showSuccessMessage = false;
            notifyListeners();
          }
        });
      } catch (e) {
        print('Error creating transaction from scan: $e');
        print('Error stack trace: ${StackTrace.current}');
        errorMessage = 'Failed to add transaction: ${e.toString()}';
        isConverting = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error in addTransaction: $e');
      errorMessage = 'Failed to add transaction: ${e.toString()}';
      isConverting = false;
      notifyListeners();
    }
  }

  // Method to clear current scan and start over
  void clearScan() {
    _scannedImage = null;
    _scanResults = null;
    _hasScannedResults = false;
    _showSuccessMessage = false; // Clear success message
    amountController.text = '';
    scannedAmount = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> takePhoto() async {
    await scanForPreview();
  }

  Future<void> convertCurrency() async {
    isConverting = true;
    clearState();
    notifyListeners();

    try {
      if (selectedImage != null) {
        print('Converting currency with image: ${selectedImage!.path}');
        final data = await _currencyService.analyzeAndConvertImage(
          selectedImage!,
          sourceCurrency:
              currentCountryCode == 'TN'
                  ? 'TND'
                  : 'EUR', // Fixed parameter name
          targetCurrency: 'TND', // Set a default target currency
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

          print(
            'Processed bill data: $scannedAmount, $convertedAmount $convertedCurrencySymbol',
          );
        }

        // Handle tax refund data
        if (data['taxRefund'] != null) {
          final taxRefund = data['taxRefund'];
          isTaxRefundAvailable = taxRefund['available'] ?? false;
          showTips = true; // Always show tips section

          print('Tax refund available: $isTaxRefundAvailable');

          if (isTaxRefundAvailable) {
            // Handle refund amount
            if (taxRefund['amount'] != null) {
              final refundAmount = taxRefund['amount'];
              taxRefundAmount = double.tryParse(
                refundAmount['value'].toString(),
              );
              taxRefundCurrency = refundAmount['currency'];
              print('Set refund amount: $taxRefundAmount $taxRefundCurrency');
            }

            // Handle instructions
            taxRefundInstructions = taxRefund['instructions']?.toString();
            print('Set instructions: $taxRefundInstructions');

            // Handle requirements
            if (taxRefund['requirements'] != null) {
              taxRefundRequirements = List<String>.from(
                taxRefund['requirements'],
              );
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
              convertedMinAmount = double.tryParse(
                minAmount['value']?.toString() ?? '',
              );
              convertedMinCurrency = minAmount['currency'];
              print(
                'Set minimum amount: $convertedMinAmount $convertedMinCurrency',
              );
            }
          }
        }

        notifyListeners();
      } else {
        errorMessage = "Please take a photo first";
        notifyListeners();
      }
    } catch (e) {
      print('Error during conversion: $e');
      errorMessage = "Error converting currency: $e";
      notifyListeners();
    } finally {
      print(
        'Final state - showTips: $showTips, isTaxRefundAvailable: $isTaxRefundAvailable',
      );
      print('Requirements: $taxRefundRequirements');
      print('Instructions: $taxRefundInstructions');
      isConverting = false;
      notifyListeners();
    }
  }

  void clearState() {
    errorMessage = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
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
    _showSuccessMessage = false;
    notifyListeners();
  }

  // Compress image before upload to avoid 413 errors
  Future<XFile?> compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 60, // Adjust as needed
      minWidth: 1200,
      minHeight: 1200,
    );
    if (result == null) return null;
    return XFile(result.path);
  }
}

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
