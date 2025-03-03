import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/currency_service.dart';

class CurrencyViewModel extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  String? sourceCountry;
  String? targetCountry;
  String? scannedAmount;
  double? convertedAmount;
  String? convertedCurrencySymbol;
  bool isTaxRefundAvailable = false;
  String? taxRefundMessage;
  List<String> taxRefundTips = [];
  bool isConverting = false;
  bool isImageProcessing = false;
  bool showTips = false;
  XFile? selectedImage;
  String? errorMessage;
  String? sourceCountryName;
  String? targetCountryName;
  double? taxRefundAmount;
  String? taxRefundCurrency;
  List<String> taxRefundRequirements = [];
  String? taxRefundInstructions;
  double? convertedMinAmount;
  String? convertedMinCurrency;

  final TextEditingController amountController = TextEditingController();

  CurrencyViewModel() {
    // No need to fetch currencies
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
    } finally {
      isImageProcessing = false;
      notifyListeners();
    }
  }

  Future<void> convertCurrency() async {
    if (targetCountry == null || sourceCountry == null) {
      print('Source or target country not selected');
      errorMessage = "Please select both countries";
      notifyListeners();
      return;
    }

    isConverting = true;
    clearState();  // Only clear conversion-related state
    notifyListeners();

    try {
      if (selectedImage != null) {
        print('Converting currency with image: ${selectedImage!.path}');
        final data = await _currencyService.analyzeAndConvertImage(
          selectedImage!,
          sourceCountry!,
          targetCountry!,
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
        
        notifyListeners();  // Notify after all data is set
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
