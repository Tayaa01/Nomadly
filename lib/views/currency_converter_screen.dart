import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../widgets/custom_bottom_nav.dart';  // Add this import

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
    final theme = Theme.of(context);

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
                        // Amount Input with currency code
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
                                        hintText: viewModel.selectedImage != null 
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

                        // Country Inputs Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildCountryInput(
                                label: 'From',
                                hint: 'FR',
                                onChanged: (value) => viewModel.sourceCountry = value.toUpperCase(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                Icons.swap_horiz,
                                color: Color(0xFF4CD964),
                                size: 28,
                              ),
                            ),
                            Expanded(
                              child: _buildCountryInput(
                                label: 'To',
                                hint: 'US',
                                onChanged: (value) => viewModel.targetCountry = value.toUpperCase(),
                              ),
                            ),
                          ],
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
                        if (viewModel.convertedAmount != null)
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
                                const Text(
                                  'Converted Amount',
                                  style: TextStyle(
                                    color: Color(0xFFA5A5A5),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${viewModel.convertedAmount?.toStringAsFixed(2)} ${viewModel.convertedCurrencySymbol}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Action Buttons with updated style
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF333333),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: viewModel.isImageProcessing
                                    ? null
                                    : viewModel.takePhoto,
                                icon: viewModel.isImageProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: viewModel.isConverting
                                    ? null
                                    : viewModel.convertCurrency,
                                child: viewModel.isConverting
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
                          const SizedBox(height: 24),
                          const Text(
                            'Tax Refund Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (viewModel.isTaxRefundAvailable) ...[
                            // Tax Refund Amount
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4CD964),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Estimated Tax Refund',
                                    style: TextStyle(
                                      color: Color(0xFFA5A5A5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${viewModel.taxRefundAmount?.toStringAsFixed(2)} ${viewModel.taxRefundCurrency}',
                                    style: const TextStyle(
                                      color: Color(0xFF4CD964),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Instructions
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF4CD964),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'How to get your refund',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    viewModel.taxRefundInstructions ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Requirements
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.checklist,
                                        color: Color(0xFF4CD964),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Requirements',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...viewModel.taxRefundRequirements.map((req) =>
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ',
                                            style: TextStyle(
                                              color: Color(0xFF4CD964),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              req,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        viewModel.convertedMinAmount != null
                                            ? Icons.info_outline
                                            : Icons.error_outline,
                                        color: const Color(0xFF4CD964),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          viewModel.taxRefundMessage ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (viewModel.convertedMinAmount != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Minimum amount: ${viewModel.convertedMinAmount?.toStringAsFixed(2)} ${viewModel.convertedMinCurrency}',
                                      style: const TextStyle(
                                        color: Color(0xFF4CD964),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
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
          currentIndex: 2,  // Currency converter is index 2
          onTap: (index) {
            if (index != 2) {  // If not current tab
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              }
              // Add other navigation cases here as needed
            }
          },
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
        border: Border.all(
          color: const Color(0xFF4CD964).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
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
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 24,
              ),
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
