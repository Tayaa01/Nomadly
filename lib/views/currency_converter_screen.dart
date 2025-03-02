import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../widgets/custom_bottom_nav.dart';
// Fix the import for Country class
import '../models/country.dart' as country_model;

class CurrencyConverterScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const CurrencyConverterScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => CurrencyViewModel(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: const Text(
            'Currency Converter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: const Color(0xFF4CD964),
              ),
              onPressed: toggleTheme,
            ),
          ],
        ),
        body: Consumer<CurrencyViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Top Section with solid color
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Amount Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4CD964).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: viewModel.amountController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      keyboardType: TextInputType.number,
                                      enabled: false, // Disable manual input
                                      decoration: InputDecoration(
                                        hintText:
                                            viewModel.selectedImage != null
                                                ? 'Scanning...'
                                                : 'Scan image to get amount',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 24,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Display user's countries with change option
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4CD964).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: const Color(0xFF4CD964),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: viewModel.isLoadingLocation
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF4CD964),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Detecting your location...',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            viewModel.currentCountryCode != null
                                                ? 'Using: ${viewModel.sourceCountryName} (${viewModel.currentCountryCode})'
                                                : 'No country selected',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _showCountryPicker(context, viewModel);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                'Tap to change',
                                                style: TextStyle(
                                                  color: const Color(0xFF4CD964),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_location_alt_outlined,
                                  color: const Color(0xFF4CD964),
                                  size: 20,
                                ),
                                onPressed: () => _showCountryPicker(context, viewModel),
                                tooltip: 'Change country',
                              ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                  ),

                  // Rest of the content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Message (if any)
                        if (viewModel.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Results Display (if any)
                        if (viewModel.convertedAmount != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4CD964),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'From ${viewModel.sourceCountryName ?? ""}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'To ${viewModel.targetCountryName ?? ""}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      viewModel.scannedAmount ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Color(0xFF4CD964),
                                      size: 24,
                                    ),
                                    Text(
                                      '${viewModel.convertedAmount?.toStringAsFixed(2)} ${viewModel.convertedCurrencySymbol}',
                                      style: const TextStyle(
                                        color: Color(0xFF4CD964),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Action Buttons with updated style
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF333333),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed:
                                    viewModel.isImageProcessing
                                        ? null
                                        : viewModel.takePhoto,
                                icon:
                                    viewModel.isImageProcessing
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF4CD964),
                                                ),
                                          ),
                                        )
                                        : const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Color(0xFF4CD964),
                                        ),
                                label: const Text(
                                  'Scan Bill',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CD964),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed:
                                    viewModel.isConverting || viewModel.selectedImage == null
                                        ? null
                                        : viewModel.convertCurrency,
                                child:
                                    viewModel.isConverting
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Convert',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),

                        // Tax Refund Tips (if any)
                        if (viewModel.showTips) ...[
                          // ...existing tax refund UI...
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 2, // Currency converter is index 2
          onTap: (index) {
            if (index != 2) {
              // If not current tab
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (index == 1) {
                Navigator.pushReplacementNamed(context, '/tips');
              } else if (index == 3) {
                Navigator.pushReplacementNamed(context, '/translation');
              }
              // Add other navigation cases here as needed
            }
          },
        ),
      ),
    );
  }

  // Improve country picker dialog
  void _showCountryPicker(BuildContext context, CurrencyViewModel viewModel) {
    // Create a list of common countries manually
    final commonCountries = [
      {'code': 'US', 'name': 'United States'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'IT', 'name': 'Italy'},
      {'code': 'ES', 'name': 'Spain'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'JP', 'name': 'Japan'},
      {'code': 'CN', 'name': 'China'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'BR', 'name': 'Brazil'},
      {'code': 'IN', 'name': 'India'},
      {'code': 'TN', 'name': 'Tunisia'},
      {'code': 'MA', 'name': 'Morocco'},
      {'code': 'EG', 'name': 'Egypt'},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Select Source Country',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'The country where the bill was issued',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF4CD964)),
                      onPressed: () {
                        Navigator.pop(context);
                        viewModel.getUserLocation();
                      },
                      tooltip: 'Detect location',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: commonCountries.length,
                  itemBuilder: (context, index) {
                    final country = commonCountries[index];
                    return _buildCountryOption(
                      context, 
                      viewModel, 
                      country['code']!, 
                      country['name']!
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CD964),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Make country options more visually distinct
  Widget _buildCountryOption(BuildContext context, CurrencyViewModel viewModel, String code, String name) {
    final isSelected = viewModel.currentCountryCode == code;
    
    return InkWell(
      onTap: () async {
        await viewModel.setCountry(code, name);
        Navigator.of(context).pop();
      },
      child: Container(
        color: isSelected ? const Color(0xFF4CD964).withOpacity(0.15) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF4CD964) : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CD964),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryInput({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const Spacer(),
              Icon(
                label == 'From' ? Icons.flight_takeoff : Icons.flight_land,
                color: const Color(0xFF4CD964),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 24),
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
