import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../widgets/app_drawer.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function toggleTheme;

  const ExpenseTrackerScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCurrency = 'EUR';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize the ViewModel
    Future.microtask(() {
      Provider.of<ExpenseViewModel>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Method to display the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF4CD964),
              onPrimary: Colors.white,
              surface: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Update the form's appearance
  void _showAddExpenseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with icon
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: const Color(0xFF4CD964),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add an Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Amount field with improved decoration
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4CD964)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFF4CD964).withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4CD964), width: 2),
                        ),
                        labelStyle: TextStyle(
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFF4CD964).withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4CD964), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                      ),
                      dropdownColor: widget.isDarkMode ? const Color(0xFF333333) : Colors.white,
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: ['EUR', 'USD', 'GBP', 'JPY', 'TND']
                          .map((currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date picker with improved decoration
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF4CD964)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color(0xFF4CD964).withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4CD964), width: 2),
                    ),
                    labelStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description with improved decoration
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description, color: Color(0xFF4CD964)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF4CD964).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4CD964), width: 2),
                  ),
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Add button (same style as TravelGroupDetailScreen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CD964),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to save a transaction
  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
      
      final transaction = Transaction(
        originalAmount: double.parse(_amountController.text),
        originalCurrency: _selectedCurrency,
        description: _descriptionController.text,
        createdAt: _selectedDate,
      );
      
      viewModel.addTransaction(transaction).then((_) {
        // Reset the form
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCurrency = 'EUR';
          _selectedDate = DateTime.now();
        });
        
        Navigator.pop(context); // Close the form
        
        // Display a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      });
    }
  }

  // Group transactions by date for better organization
  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final groupedTransactions = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      // Create date without time part
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      
      groupedTransactions[date]!.add(transaction);
    }
    
    // Sort dates in descending order (newest first)
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return {
      for (var key in sortedKeys) key: groupedTransactions[key]!
    };
  }

  // Format date header nicely
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name (e.g., "Monday")
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date); // Month and day (e.g., "April 15")
    } else {
      return DateFormat('MMM d, yyyy').format(date); // With year for older dates
    }
  }

  // Build a visually appealing transaction card
  Widget _buildTransactionCard(Transaction transaction) {
    // Determine if this is incoming or outgoing (negative amount)
    final isOutgoing = true; // Assume all are expenses for now
    
    // Get currency symbol
    final currencySymbol = _getCurrencySymbol(transaction.originalCurrency);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Transaction icon with colored background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOutgoing 
                        ? const Color(0xFF4CD964).withOpacity(0.1)
                        // ignore: dead_code
                        : const Color(0xFF5AC8FA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    // ignore: dead_code
                    isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
                    // ignore: dead_code
                    color: isOutgoing ? const Color(0xFF4CD964) : const Color(0xFF5AC8FA),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Description and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(transaction.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show primary amount (converted if available)
                    Text(
                      transaction.convertedAmount != null
                          ? '${_getCurrencySymbol(transaction.convertedCurrency ?? '')}${transaction.convertedAmount!.toStringAsFixed(2)}'
                          : '$currencySymbol${transaction.originalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOutgoing 
                            ? const Color(0xFF4CD964)
                            // ignore: dead_code
                            : const Color(0xFF5AC8FA),
                      ),
                    ),
                    
                    // Show secondary amount if available
                    if (transaction.convertedAmount != null && transaction.convertedCurrency != transaction.originalCurrency)
                      Text(
                        '$currencySymbol${transaction.originalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            // If we have original and converted amounts, show a divider and conversion details
            if (transaction.convertedAmount != null && transaction.convertedCurrency != transaction.originalCurrency) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Converted from ${transaction.originalCurrency} to ${transaction.convertedCurrency}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to get currency symbol
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'TND': return 'DT';
      default: return currencyCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Expense Tracker',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/expense-tracker'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseForm,
        backgroundColor: const Color(0xFF4CD964),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add an expense'),
        tooltip: 'Add new transaction',
        heroTag: 'addExpense',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<ExpenseViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }
          
          if (viewModel.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions recorded',
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showAddExpenseForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CD964),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add a transaction'),
                  ),
                ],
              ),
            );
          } else {
            // Group transactions by date
            final groupedTransactions = _groupTransactionsByDate(viewModel.transactions);
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedTransactions.length,
              itemBuilder: (context, index) {
                final dateGroup = groupedTransactions.keys.elementAt(index);
                final transactions = groupedTransactions[dateGroup]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _formatDateHeader(dateGroup),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                    
                    // Transactions for this date
                    ...transactions.map((transaction) => _buildTransactionCard(transaction)),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}