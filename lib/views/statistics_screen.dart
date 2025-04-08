import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../models/transaction_summary.dart';
import '../models/saving_summary.dart';
import '../services/finance_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FinanceService _financeService = FinanceService();
  List<TransactionSummary> _transactions = [];
  List<SavingSummary> _savings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Current week's start and end dates
  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;

  @override
  void initState() {
    super.initState();
    _initializeWeekDates();
    _fetchData();
  }

  // Initialize the week dates
  void _initializeWeekDates() {
    // Set to March 2025 dates to match your sample data instead of using current date
    _currentWeekStart = DateTime(2025, 3, 1);
    _currentWeekEnd = DateTime(2025, 3, 7);
    
    // Alternative: Keep code to handle current date dynamically
    // final now = DateTime.now();
    // _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    // _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  // Navigation methods for week selection
  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
      _fetchData();
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _currentWeekEnd = _currentWeekEnd.add(const Duration(days: 7));
      _fetchData();
    });
  }

  // Fetch financial data
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final transactions = await _financeService.getTransactionsByDay();
      final savings = await _financeService.getSavingsByDay();
      
      // Filter transactions to current week
      final filteredTransactions = transactions.where((t) {
        final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
        final startDate = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
        final endDate = DateTime(_currentWeekEnd.year, _currentWeekEnd.month, _currentWeekEnd.day);
        
        return !transactionDate.isBefore(startDate) && 
               !transactionDate.isAfter(endDate);
      }).toList();
      
      // Filter savings to current week
      final filteredSavings = savings.where((s) {
        final savingDate = DateTime(s.date.year, s.date.month, s.date.day);
        final startDate = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
        final endDate = DateTime(_currentWeekEnd.year, _currentWeekEnd.month, _currentWeekEnd.day);
        
        return !savingDate.isBefore(startDate) && 
               !savingDate.isAfter(endDate);
      }).toList();

      setState(() {
        _transactions = filteredTransactions;
        _savings = filteredSavings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fix the duplicate title in the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Financial Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/statistics'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
              ),
            )
          : _hasError
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: const Color(0xFF4CD964),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWeekSelector(),
                          const SizedBox(height: 20),
                          _buildTransactionsCard(),
                          const SizedBox(height: 20),
                          _buildSavingsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // Error view widget
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, 
            color: Colors.redAccent, 
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading data',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Week selector widget
  Widget _buildWeekSelector() {
    final dateFormat = DateFormat('MMM d');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _goToPreviousWeek,
        ),
        Text(
          '${dateFormat.format(_currentWeekStart)} - ${dateFormat.format(_currentWeekEnd)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onPressed: _goToNextWeek,
        ),
      ],
    );
  }

  // Transactions card widget
  Widget _buildTransactionsCard() {
    if (_transactions.isEmpty) {
      return _buildEmptyCard('No transactions for this week');
    }

    // Calculate totals for the summary
    final totalOriginal = _transactions.fold(0.0, (sum, item) => sum + item.totalOriginal);
    final totalConverted = _transactions.fold(0.0, (sum, item) => sum + item.totalConverted);
    final totalCount = _transactions.fold(0, (sum, item) => sum + item.count);

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Count', '$totalCount'),
                _buildSummaryItem('Original', '\$${totalOriginal.toStringAsFixed(2)}'),
                _buildSummaryItem('Converted', '\$${totalConverted.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildTransactionsChart(),
            ),
          ],
        ),
      ),
    );
  }

  // Savings card widget
  Widget _buildSavingsCard() {
    if (_savings.isEmpty) {
      return _buildEmptyCard('No savings data for this week');
    }

    // Calculate total savings
    final totalSavings = _savings.fold(0.0, (sum, item) => sum + item.totalSavings);
    final totalCount = _savings.fold(0, (sum, item) => sum + item.count);

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Savings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Count', '$totalCount'),
                _buildSummaryItem('Total Savings', '\$${totalSavings.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSavingsChart(),
            ),
          ],
        ),
      ),
    );
  }

  // Summary item widget
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Empty card widget
  Widget _buildEmptyCard(String message) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Transactions chart widget
  Widget _buildTransactionsChart() {
    // Generate data points for all days of the week
    final Map<int, TransactionSummary> transactionMap = {};
    
    // Map transactions to weekday (1-7)
    for (var t in _transactions) {
      // Convert API date to weekday (1-7)
      final weekday = t.date.weekday;
      transactionMap[weekday] = t;
    }

    // Create spots for every day of the week
    final spots = List<FlSpot>.generate(7, (index) {
      final weekday = index + 1; // 1-7 for Monday-Sunday
      final dayTransaction = transactionMap[weekday];
      final value = dayTransaction?.totalOriginal ?? 0.0;
      return FlSpot(weekday.toDouble(), value);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Full weekday names
                const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                
                if (value >= 1 && value <= 7 && value.toInt() == value) {
                  // Get transaction data for this day if it exists
                  final dayTransaction = transactionMap[value.toInt()];
                  final count = dayTransaction?.count ?? 0;
                  
                  return SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdayNames[value.toInt()],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (count > 0)
                          Text(
                            '($count)',  // Display count in parentheses
                            style: const TextStyle(
                              color: Color(0xFF4CD964),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40, // Increased to accommodate two lines of text
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4CD964),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4CD964).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // Savings chart widget
  Widget _buildSavingsChart() {
    // Generate data points for all days of the week
    final Map<int, SavingSummary> savingsMap = {};
    
    // Map savings to weekday (1-7)
    for (var s in _savings) {
      // Convert API date to weekday (1-7)
      final weekday = s.date.weekday;
      savingsMap[weekday] = s;
    }

    // Create spots for every day of the week
    final spots = List<FlSpot>.generate(7, (index) {
      final weekday = index + 1; // 1-7 for Monday-Sunday
      final daySaving = savingsMap[weekday];
      final value = daySaving?.totalSavings ?? 0.0;
      return FlSpot(weekday.toDouble(), value);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Full weekday names
                const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                
                if (value >= 1 && value <= 7 && value.toInt() == value) {
                  // Get savings data for this day if it exists
                  final daySaving = savingsMap[value.toInt()];
                  final count = daySaving?.count ?? 0;
                  
                  return SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdayNames[value.toInt()],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (count > 0)
                          Text(
                            '($count)',  // Display count in parentheses
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40, // Increased to accommodate two lines of text
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.amber.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
