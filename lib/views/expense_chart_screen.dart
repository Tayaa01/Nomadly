import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../widgets/app_drawer.dart';

class ExpenseChartScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function toggleTheme;

  const ExpenseChartScreen({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Color> _chartColors = [
    const Color(0xFF4CD964), // Green
    const Color(0xFF5AC8FA), // Light Blue
    const Color(0xFFFF9500), // Orange
    const Color(0xFFFF2D55), // Red
    const Color(0xFF5856D6), // Purple
    const Color(0xFFFFCC00), // Yellow
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Expense Analysis',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4CD964),
          unselectedLabelColor: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
          indicatorColor: const Color(0xFF4CD964),
          tabs: const [
            Tab(text: 'By Category'),
            Tab(text: 'By Day'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/expense-tracker'),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Category chart (pie chart)
          _buildCategoryChart(),
          // Daily chart (bar chart)
          _buildDailyChart(),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Consumer<ExpenseViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CD964)));
        }

        return FutureBuilder<Map<String, double>>(
          future: viewModel.getExpensesByCategory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No expense data available',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            double totalAmount = data.values.fold(0, (a, b) => a + b);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Chart title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  
                  // Pie chart
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(data, totalAmount),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(enabled: true),
                      ),
                    ),
                  ),
                  
                  // Legend
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: _buildLegend(data, totalAmount),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data, double totalAmount) {
    int colorIndex = 0;
    return data.entries.map((entry) {
      final percent = totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0;
      final color = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: color,
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> data, double totalAmount) {
    int colorIndex = 0;
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: data.entries.map((entry) {
        final color = _chartColors[colorIndex % _chartColors.length];
        final percent = totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0;
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} (${entry.value.toStringAsFixed(2)}€, ${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDailyChart() {
    return Consumer<ExpenseViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CD964)));
        }

        return FutureBuilder<Map<DateTime, double>>(
          future: viewModel.getExpensesByDay(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No expense data available',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            
            // Sort the data by date
            final sortedEntries = data.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            
            // Only display the last 7 days of data
            final displayEntries = sortedEntries.length > 7 
                ? sortedEntries.sublist(sortedEntries.length - 7) 
                : sortedEntries;
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Chart title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Expenses by Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  
                  // Bar chart
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: displayEntries.isEmpty 
                            ? 100 
                            : displayEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < displayEntries.length) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      DateFormat('MM/dd').format(displayEntries[value.toInt()].key),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 28,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(
                          displayEntries.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: displayEntries[index].value,
                                color: const Color(0xFF4CD964),
                                width: 14,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Legend or additional info
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${displayEntries.fold(0.0, (sum, entry) => sum + entry.value).toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'Last ${displayEntries.length} days',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}