import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../widgets/app_drawer.dart'; // Change import

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

    return WillPopScope(
      onWillPop: () async {
        // Navigate to home screen when back button is pressed
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false; // Prevents default back button behavior
      },
      child: ChangeNotifierProvider(
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
          drawer: const AppDrawer(currentRoute: '/currency-converter'),
          body: Consumer<CurrencyViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return _buildLoadingSkeleton(context);
              }
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
                                  child:
                                      viewModel.isLoadingLocation
                                          ? Row(
                                            children: [
                                              SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF4CD964)),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                viewModel.currentCountryCode !=
                                                        null
                                                    ? 'Using: ${viewModel.sourceCountryName} (${viewModel.currentCountryCode})'
                                                    : 'No country selected',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _showCountryPicker(
                                                    context,
                                                    viewModel,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Text(
                                                    'Tap to change',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF4CD964,
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                  onPressed:
                                      () => _showCountryPicker(
                                        context,
                                        viewModel,
                                      ),
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

                          // Success message when transaction is added
                          if (viewModel.showSuccessMessage)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Transaction added successfully!',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Action Buttons - replaced with new implementation
                          _buildActionButtons(viewModel),

                          // Tax Refund Tips (if any)
                          if (viewModel.showTips) ...[
                            // ...existing tax refund UI...
                          ],

                          // Add the statistics button
                          _buildStatisticsButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
                      country['name']!,
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
  Widget _buildCountryOption(
    BuildContext context,
    CurrencyViewModel viewModel,
    String code,
    String name,
  ) {
    final isSelected = viewModel.currentCountryCode == code;

    return InkWell(
      onTap: () async {
        await viewModel.setCountry(code, name);
        Navigator.of(context).pop();
      },
      child: Container(
        color:
            isSelected
                ? const Color(0xFF4CD964).withOpacity(0.15)
                : Colors.transparent,
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
                        color:
                            isSelected ? const Color(0xFF4CD964) : Colors.white,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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

  // Add a button in the UI section of the screen
  Widget _buildStatisticsButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/statistics');
        },
        icon: const Icon(Icons.bar_chart),
        label: const Text('View Financial Statistics'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CD964),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Replace the action buttons section with this improved version
  Widget _buildActionButtons(CurrencyViewModel viewModel) {
    if (viewModel.hasScannedResults) {
      // Show "Add Transaction" and "New Scan" buttons after successful scan
      return Column(
        children: [
          // Results Display (if available)
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CD964), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Results',
                  style: const TextStyle(
                    color: Color(0xFF4CD964),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'From ${viewModel.sourceCountryName ?? ""}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    Text(
                      'To ${viewModel.targetCountryName ?? ""}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                      '${viewModel.convertedAmount?.toStringAsFixed(2) ?? ""} ${viewModel.convertedCurrencySymbol ?? ""}',
                      style: const TextStyle(
                        color: Color(0xFF4CD964),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Add a note about the automatic conversion
                if (viewModel.scanResults != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rate: ${viewModel.scanResults!['conversion']['rate']?.toStringAsFixed(2) ?? "Unknown"}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: viewModel.clearScan,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('New Scan'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CD964),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      viewModel.isConverting ? null : viewModel.addTransaction,
                  icon:
                      viewModel.isConverting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                          : const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'Add Transaction',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Show "Scan" button when there are no scan results yet
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CD964),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: viewModel.isScanning ? null : viewModel.scanForPreview,
        icon:
            viewModel.isScanning
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
                : const Icon(Icons.camera_alt_rounded, color: Colors.black),
        label: const Text(
          'Scan Bill',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  // Add a skeleton loader widget
  Widget _buildLoadingSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF232323),
        highlightColor: const Color(0xFF4CD964).withOpacity(0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount skeleton
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            // Country skeleton
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            // Scan button skeleton
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            // Statistics button skeleton
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ],
        ),
      ),
    );
  }
}
