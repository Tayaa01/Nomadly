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
      return;
    }

    isConverting = true;
    scannedAmount = null;
    convertedAmount = null;
    convertedCurrencySymbol = null;
    isTaxRefundAvailable = false;
    taxRefundMessage = null;
    taxRefundTips = [];
    showTips = false;
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

        if (data['bill'] != null) {
          final bill = data['bill'];
          if (bill['amount'] != null) {
            scannedAmount = '${bill['amount']['value']} ${bill['amount']['currency']}';
          }
          if (bill['convertedAmount'] != null) {
            convertedAmount = double.tryParse(bill['convertedAmount']['value'].toString());
            convertedCurrencySymbol = bill['convertedAmount']['currency'];
          }
        }
        if (data['taxRefund'] != null) {
          isTaxRefundAvailable = data['taxRefund']['available'];
          taxRefundMessage = data['taxRefund']['message'];
          if (data['taxRefund']['tips'] != null) {
            taxRefundTips = List<String>.from(data['taxRefund']['tips']);
          }
          showTips = true;
        } else {
          isTaxRefundAvailable = false;
          taxRefundMessage = 'Tax refund is not available for this transaction.';
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error converting currency: $e');
    } finally {
      isConverting = false;
      notifyListeners();
    }
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
