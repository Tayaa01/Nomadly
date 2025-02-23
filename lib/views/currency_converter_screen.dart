import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/currency_viewmodel.dart';

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
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Currency Converter',
              style: TextStyle(color: Color(0xFFFFFFFF))),
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: theme.colorScheme.primary,
              ),
              onPressed: toggleTheme,
            ),
          ],
        ),
        body: Consumer<CurrencyViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: viewModel.amountController,
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        keyboardType: TextInputType.number,
                        enabled: viewModel.selectedImage == null,
                        decoration: InputDecoration(
                          hintText: viewModel.selectedImage != null 
                              ? 'Amount will be extracted from image' 
                              : 'Enter amount',
                          hintStyle: const TextStyle(color: Color(0xFFA5A5A5)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Source Country Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E1E1E),
                          hint: const Text('Select source country',
                              style: TextStyle(color: Color(0xFFA5A5A5))),
                          value: viewModel.sourceCountry,
                          isExpanded: true,
                          items: ['FR', 'US', 'UK', 'JP']
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                        style: const TextStyle(
                                            color: Color(0xFFFFFFFF))),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            viewModel.sourceCountry = newValue;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Country Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E1E1E),
                          hint: const Text('Select target country',
                              style: TextStyle(color: Color(0xFFA5A5A5))),
                          value: viewModel.targetCountry,
                          isExpanded: true,
                          items: ['FR', 'US', 'UK', 'JP']
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                        style: const TextStyle(
                                            color: Color(0xFFFFFFFF))),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            viewModel.targetCountry = newValue;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Results Display
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

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E1E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: viewModel.isImageProcessing
                                ? null
                                : viewModel.takePhoto,
                            icon: viewModel.isImageProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFF2F2F2)),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Color(0xFFF2F2F2)),
                            label: const Text('Scan',
                                style: TextStyle(color: Color(0xFFF2F2F2))),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CD964),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: viewModel.isConverting
                                ? null
                                : viewModel.convertCurrency,
                            child: viewModel.isConverting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Convert',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    )),
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.isConverting)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    // Tax Refund Tips
                    if (viewModel.showTips) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Tax Refund Tips',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.isTaxRefundAvailable) ...[
                        ...viewModel.taxRefundTips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF4CD964),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF4CD964),
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
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
