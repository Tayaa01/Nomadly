import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/app_drawer.dart';
import '../models/transaction.dart'; // Updated to use Transaction directly
// Use transaction service instead
import '../viewmodels/expense_viewmodel.dart'; // Add the ViewModel for better data handling
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filter periods
  final List<String> _filterPeriods = ['Last 7 Days', 'Last 30 Days', 'This Month', 'This Year'];
  String _selectedPeriod = 'Last 7 Days';
  
  // Currency display options
  String _displayCurrency = 'Original';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch data
    Future.microtask(() {
      final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
      viewModel.init().then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter transactions based on selected period
  List<Transaction> _getFilteredTransactions(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        final startDate = today.subtract(const Duration(days: 6));
        return allTransactions.where((t) => 
          !t.createdAt.isBefore(startDate) && 
          !t.createdAt.isAfter(now)
        ).toList();
        
      case 'Last 30 Days':
        final startDate = today.subtract(const Duration(days: 29));
        return allTransactions.where((t) => 
          !t.createdAt.isBefore(startDate) && 
          !t.createdAt.isAfter(now)
        ).toList();
        
      case 'This Month':
        final startDate = DateTime(now.year, now.month, 1);
        return allTransactions.where((t) => 
          !t.createdAt.isBefore(startDate) && 
          !t.createdAt.isAfter(now)
        ).toList();
        
      case 'This Year':
        final startDate = DateTime(now.year, 1, 1);
        return allTransactions.where((t) => 
          !t.createdAt.isBefore(startDate) && 
          !t.createdAt.isAfter(now)
        ).toList();
        
      default:
        return allTransactions;
    }
  }

  // Get the amount based on selected currency display option
  double _getAmount(Transaction transaction) {
    if (_displayCurrency == 'Original' || transaction.convertedAmount == null) {
      return transaction.originalAmount;
    } else {
      return transaction.convertedAmount!;
    }
  }

  // Group transactions by date
  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final groupedData = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year, 
        transaction.createdAt.month, 
        transaction.createdAt.day
      );
      
      if (!groupedData.containsKey(date)) {
        groupedData[date] = [];
      }
      
      groupedData[date]!.add(transaction);
    }
    
    return groupedData;
  }
  
  // Group transactions by currency
  Map<String, double> _groupTransactionsByCurrency(List<Transaction> transactions) {
    final groupedData = <String, double>{};
    
    for (final transaction in transactions) {
      final currency = _displayCurrency == 'Original' || transaction.convertedCurrency == null
          ? transaction.originalCurrency
          : transaction.convertedCurrency!;
      
      final amount = _getAmount(transaction);
      
      if (!groupedData.containsKey(currency)) {
        groupedData[currency] = 0;
      }
      
      groupedData[currency] = (groupedData[currency] ?? 0) + amount;
    }
    
    return groupedData;
  }

  // Get currency symbol for display
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

  Widget _buildLoadingSkeleton() {
    return Center(
      child: ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF232323),
              highlightColor: const Color(0xFF4CD964).withOpacity(0.25),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large header/chart skeleton
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF232323),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title skeleton
                          Container(
                            height: 20,
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle skeleton
                          Container(
                            height: 14,
                            width: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Value skeleton
                          Container(
                            height: 28,
                            width: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Button skeleton
                          Container(
                            height: 48,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Financial Statistics',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4CD964),
          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          indicatorColor: const Color(0xFF4CD964),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Timeline'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/statistics'),
      body: _isLoading 
      ? _buildLoadingSkeleton()
      : _errorMessage.isNotEmpty
        ? _buildErrorView()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTimelineTab(),
              _buildCategoriesTab(),
            ],
          ),
    );
  }

  // Error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              
              Provider.of<ExpenseViewModel>(context, listen: false).init().then((_) {
                setState(() {
                  _isLoading = false;
                });
              }).catchError((error) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.toString();
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Overview tab
  Widget _buildOverviewTab() {
    final viewModel = Provider.of<ExpenseViewModel>(context);
    final transactions = _getFilteredTransactions(viewModel.transactions);
    
    if (transactions.isEmpty) {
      return _buildEmptyState('No transactions found for this period');
    }
    
    // Calculate summary data
    final totalSpent = transactions.fold(0.0, 
      (sum, t) => sum + (_displayCurrency == 'Original' || t.convertedAmount == null 
        ? t.originalAmount 
        : t.convertedAmount!));
    
    final transactionsByCurrency = _groupTransactionsByCurrency(transactions);
    final transactionsByDate = _groupTransactionsByDate(transactions);
    
    final lastTransactionDate = transactions.isNotEmpty 
        ? transactions.first.createdAt 
        : DateTime.now();
    
    final avgPerDay = transactionsByDate.isNotEmpty 
        ? totalSpent / transactionsByDate.length 
        : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selection and currency toggle
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildPeriodDropdown(),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildCurrencyToggle(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  _formatAmount(totalSpent),
                  const Color(0xFF4CD964),
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Daily Average',
                  _formatAmount(avgPerDay),
                  const Color(0xFF5AC8FA),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Transactions',
                  transactions.length.toString(),
                  const Color(0xFFFF9500),
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Last Transaction',
                  DateFormat('MMM d').format(lastTransactionDate),
                  const Color(0xFFFF2D55),
                  Icons.history,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Currency distribution
          Text(
            'Currency Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Currency pie chart
          AspectRatio(
            aspectRatio: 1.3,
            child: _buildCurrencyPieChart(transactionsByCurrency),
          ),
        ],
      ),
    );
  }

  // Timeline tab
  Widget _buildTimelineTab() {
    final viewModel = Provider.of<ExpenseViewModel>(context);
    final transactions = _getFilteredTransactions(viewModel.transactions);

    // Determine the date range based on the selected period
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Last 7 Days':
        startDate = today.subtract(const Duration(days: 6));
        break;
      case 'Last 30 Days':
        startDate = today.subtract(const Duration(days: 29));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = today.subtract(const Duration(days: 6));
    }

    // Group transactions by date
    final transactionsByDate = _groupTransactionsByDate(transactions);

    // Generate all dates in the range
    final List<DateTime> allDates = [];
    for (DateTime date = startDate; !date.isAfter(today); date = date.add(const Duration(days: 1))) {
      allDates.add(DateTime(date.year, date.month, date.day));
    }

    // Sort from newest to oldest for the list view
    allDates.sort((a, b) => b.compareTo(a));

    // Use LayoutBuilder to dynamically adjust chart height
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        // Dynamically calculate chart height
        final chartHeight = isLandscape
            ? constraints.maxHeight * 0.6 // Use 60% of height in landscape
            : constraints.maxHeight * 0.4; // Use 40% of height in portrait

        return SingleChildScrollView(
          child: Column(
            children: [
              // Period selection and currency toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPeriodDropdown(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _buildCurrencyToggle(),
                    ),
                  ],
                ),
              ),

              // Expense trend chart with dynamic height
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Expense Trend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        height: chartHeight,
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        width: double.infinity,
                        child: _buildExpenseTrendChart(transactionsByDate, allDates),
                      ),
                      // Add buffer space at the bottom of the card
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Add more spacing between chart and list
              const SizedBox(height: 16),

              // Detailed daily expenses with flexible height
              ListView.builder(
                shrinkWrap: true, // Allow ListView to take only the required space
                physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                padding: EdgeInsets.fromLTRB(
                  isLandscape ? 8.0 : 16.0,
                  12.0, // Increased top padding
                  isLandscape ? 8.0 : 16.0,
                  isLandscape ? 8.0 : 16.0,
                ),
                itemCount: allDates.length,
                itemBuilder: (context, index) {
                  final date = allDates[index];
                  final dayTransactions = transactionsByDate[date] ?? [];

                  // Calculate total for the day
                  final totalForDay = dayTransactions.isEmpty
                      ? 0.0
                      : dayTransactions.fold(0.0, (sum, t) => sum + _getAmount(t));

                  // Use more compact tiles in landscape mode
                  return isLandscape
                      ? _buildCompactDayTile(date, totalForDay, dayTransactions)
                      : _buildExpandableDayTile(date, totalForDay, dayTransactions);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add these helper methods for different tile styles
  Widget _buildExpandableDayTile(DateTime date, double totalForDay, List<Transaction> dayTransactions) {
    return ExpansionTile(
      initiallyExpanded: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEE, MMM d').format(date),
            style: TextStyle(
              fontWeight: totalForDay > 0 ? FontWeight.bold : FontWeight.normal,
              color: totalForDay > 0 
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
          ),
          Text(
            _formatAmount(totalForDay),
            style: TextStyle(
              color: totalForDay > 0 ? const Color(0xFF4CD964) : Colors.grey,
              fontWeight: totalForDay > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      // Only show expansion if there are transactions
      children: dayTransactions.isEmpty 
          ? [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No transactions on this day', 
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                ),
              )
            ]
          : dayTransactions.map((transaction) => _buildTransactionListItem(transaction)).toList(),
    );
  }

  Widget _buildCompactDayTile(DateTime date, double totalForDay, List<Transaction> dayTransactions) {
    return ListTile(
      title: Text(
        DateFormat('EEE, MMM d').format(date),
        style: TextStyle(
          fontSize: 14,
          fontWeight: totalForDay > 0 ? FontWeight.bold : FontWeight.normal,
          color: totalForDay > 0 
              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
              : Colors.grey,
        ),
      ),
      trailing: Text(
        _formatAmount(totalForDay),
        style: TextStyle(
          fontSize: 14,
          color: totalForDay > 0 ? const Color(0xFF4CD964) : Colors.grey,
          fontWeight: totalForDay > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: dayTransactions.isEmpty 
          ? null
          : () => _showTransactionsDialog(date, dayTransactions),
    );
  }

  // Create a method to show transactions in a dialog for landscape mode
  void _showTransactionsDialog(DateTime date, List<Transaction> transactions) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Transactions on ${DateFormat('EEE, MMM d').format(date)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: transactions.length,
                itemBuilder: (context, index) => _buildTransactionListItem(transactions[index]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  // Extract transaction list item to a separate method for reuse
  Widget _buildTransactionListItem(Transaction transaction) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF4CD964),
        child: Icon(
          Icons.receipt,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(DateFormat('h:mm a').format(transaction.createdAt)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${transaction.originalAmount.toStringAsFixed(2)} ${transaction.originalCurrency}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (transaction.convertedAmount != null && transaction.convertedCurrency != null)
            Text(
              '${transaction.convertedAmount!.toStringAsFixed(2)} ${transaction.convertedCurrency}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  // Categories tab
  Widget _buildCategoriesTab() {
    // Since we don't have actual categories in the transaction model yet,
    // we'll just categorize by currency for now
    
    final viewModel = Provider.of<ExpenseViewModel>(context);
    final transactions = _getFilteredTransactions(viewModel.transactions);
    
    if (transactions.isEmpty) {
      return _buildEmptyState('No transactions found for this period');
    }
    
    final transactionsByCurrency = _groupTransactionsByCurrency(transactions);
    
    return Column(
      children: [
        // Period selection
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildPeriodDropdown(),
        ),
        
        // Currency distribution cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactionsByCurrency.length,
            itemBuilder: (context, index) {
              final currency = transactionsByCurrency.keys.elementAt(index);
              final amount = transactionsByCurrency[currency]!;
              
              // Calculate percentage
              final totalAmount = transactionsByCurrency.values.fold(0.0, (sum, value) => sum + value);
              final percentage = (amount / totalAmount) * 100;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1E1E1E) 
                    : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getCurrencyColor(currency).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _getCurrencySymbol(currency),
                                style: TextStyle(
                                  color: _getCurrencyColor(currency),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total expenses',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatAmount(amount, currency: currency),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: amount / totalAmount,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getCurrencyColor(currency)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CD964)),
          isExpanded: true,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
            fontSize: 14,
          ),
          dropdownColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E1E1E) 
              : Colors.white,
          items: _filterPeriods.map((period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(period),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPeriod = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _displayCurrency,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CD964)),
          isExpanded: true,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
            fontSize: 14,
          ),
          dropdownColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E1E1E) 
              : Colors.white,
          items: const [
            DropdownMenuItem(value: 'Original', child: Text('Original')),
            DropdownMenuItem(value: 'Converted', child: Text('Converted')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _displayCurrency = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E1E) 
          : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Handle potential overflow in value text
            Tooltip(
              message: value, // Show full value on long press
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18, // Reduced from 20 to fit better
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Chart widgets
  Widget _buildCurrencyPieChart(Map<String, double> transactionsByCurrency) {
    final colors = [
      const Color(0xFF4CD964),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF9500),
      const Color(0xFFFF2D55),
      const Color(0xFF5856D6),
      const Color(0xFFFFCC00),
    ];
    
    final totalAmount = transactionsByCurrency.values.fold(0.0, (sum, value) => sum + value);
    
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    
    for (final currency in transactionsByCurrency.keys) {
      final amount = transactionsByCurrency[currency]!;
      final percentage = (amount / totalAmount) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: percentage,
          title: '$currency\n${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    }
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(enabled: true),
      ),
    );
  }

  Widget _buildExpenseTrendChart(
    Map<DateTime, List<Transaction>> transactionsByDate,
    List<DateTime> sortedDates
  ) {
    if (sortedDates.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Generate date range and data points - keep as is
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    DateTime endDate = today;

    switch (_selectedPeriod) {
      case 'Last 7 Days':
        startDate = today.subtract(const Duration(days: 6));
        break;
      case 'Last 30 Days':
        startDate = today.subtract(const Duration(days: 29));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = today.subtract(const Duration(days: 6)); // Default to last 7 days
    }

    // Generate all dates in the range
    final List<DateTime> allDates = [];
    for (DateTime date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      allDates.add(DateTime(date.year, date.month, date.day));
    }

    // Prepare data points for all dates, including zero values for days without transactions
    final spots = <FlSpot>[];

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      final transactions = transactionsByDate[date] ?? [];

      final totalForDay = transactions.isEmpty 
          ? 0.0 
          : transactions.fold(0.0, (sum, t) => sum + _getAmount(t));

      spots.add(FlSpot(i.toDouble(), totalForDay));
    }

    // Wrap the chart in a better constrained widget
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate chart dimensions
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;

        // Calculate some padding to ensure values don't overflow
        final maxY = spots.fold(0.0, (max, spot) => spot.y > max ? spot.y : max);
        // Ensure we always have some visible range even if all values are 0
        final effectiveMaxY = maxY <= 0 ? 100.0 : maxY;
        final yPadding = effectiveMaxY * 0.2; // 20% padding

        return Stack(
          children: [
            // Add background grid container to prevent overflow
            Container(
              width: chartWidth,
              height: chartHeight - 40, // Reduce height to make room for x-axis labels
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // The chart itself with better constraints
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 40.0), // More bottom padding for labels
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: effectiveMaxY / 4, // Divide the chart into 4 horizontal sections
                    verticalInterval: allDates.length > 10 ? 2.0 : 1.0, // Adjust vertical lines based on data points
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 0.5, // Thinner lines
                        dashArray: [3, 3], // Shorter dash pattern
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 0.5, // Thinner lines
                        dashArray: [3, 3], // Shorter dash pattern
                      );
                    },
                  ),
                  
                  // Better titles configuration
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const SizedBox.shrink(),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Show fewer y-axis labels
                          if (value % (effectiveMaxY / 4) != 0) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9, // Smaller font
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // Fixed reserved size
                        interval: allDates.length > 14 ? 2.0 : 1.0, // Show fewer labels if many dates
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index >= 0 && index < allDates.length) {
                            final date = allDates[index];
                            
                            // Skip some labels if we have too many dates
                            final interval = allDates.length <= 7 ? 1 : (allDates.length ~/ 5);
                            bool showLabel = index % interval == 0 || index == allDates.length - 1;
                            
                            if (showLabel) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 6,
                                  child: Text(
                                    DateFormat('d MMM').format(date),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 9, // Smaller font
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  
                  // Better touch handling
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF333333) 
                          : Colors.white,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = allDates[touchedSpot.x.toInt()];
                          final amount = _formatAmount(touchedSpot.y);
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n$amount',
                            TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Smaller font
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: const Color(0xFF4CD964),
                            strokeWidth: 2,
                            dashArray: [3, 3],
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF4CD964),
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                  
                  // Better border configuration
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  
                  // Explicit boundaries to prevent overflow
                  minX: 0,
                  maxX: (allDates.length - 1).toDouble(),
                  minY: 0,
                  maxY: effectiveMaxY + yPadding,
                  
                  // Line styling
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2, // Less curved
                      preventCurveOverShooting: true, // Prevent curve overshooting
                      color: const Color(0xFF4CD964),
                      barWidth: 2.5, // Slightly thinner
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) {
                          // Show dots only for non-zero values or if we have few points
                          return spot.y > 0 || allDates.length <= 10;
                        },
                        getDotPainter: (spot, percent, barData, index) {
                          // Customize dot size based on amount (zero = smaller)
                          double size = spots[index].y > 0 ? 5 : 2;
                          
                          return FlDotCirclePainter(
                            radius: size,
                            color: const Color(0xFF4CD964),
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4CD964).withOpacity(0.15), // More subtle gradient
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CD964).withOpacity(0.2),
                            const Color(0xFF4CD964).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  // Helper methods
  String _formatAmount(double amount, {String? currency}) {
    // Use compact format for large numbers to prevent overflow
    final formatter = amount > 10000 
        ? NumberFormat.compactCurrency(
            symbol: currency != null ? _getCurrencySymbol(currency) : '',
            decimalDigits: 2,
          )
        : NumberFormat.currency(
            symbol: currency != null ? _getCurrencySymbol(currency) : '',
            decimalDigits: 2,
          );
    
    return formatter.format(amount);
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USD': return const Color(0xFF4CD964);
      case 'EUR': return const Color(0xFF5AC8FA);
      case 'GBP': return const Color(0xFFFF9500);
      case 'JPY': return const Color(0xFFFF2D55);
      case 'TND': return const Color(0xFF5856D6);
      default: return const Color(0xFFFFCC00);
    }
  }
}
