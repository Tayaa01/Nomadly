import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../widgets/custom_bottom_nav.dart';

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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Category chart (pie chart)
          _buildCategoryChart(),
          // Daily chart (bar chart)
          _buildDailyChart(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,  // Index 3 for expenses
        onTap: (index) {
          if (index != 3) {  // If not the current tab
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/currency-converter');
            } else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/translation');
            }
          }
        },
      ),
    );
  }

  // Building the pie chart for expenses by category
  Widget _buildCategoryChart() {
    return Consumer<ExpenseViewModel>(
      builder: (context, viewModel, child) {
        return FutureBuilder<Map<String, double>>(
          future: viewModel.getExpensesByCategory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyChartMessage('No data available for categories');
            }

            final categoryData = snapshot.data!;
            final categories = categoryData.keys.toList();
            final double total = categoryData.values.fold(0, (sum, value) => sum + value);

            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(categoryData, total),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Distribution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final amount = categoryData[category]!;
                              final percentage = (amount / total * 100).toStringAsFixed(1);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _chartColors[index % _chartColors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: widget.isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${amount.toStringAsFixed(2)} € ($percentage%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Building the pie chart sections
  List<PieChartSectionData> _buildPieChartSections(Map<String, double> categoryData, double total) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    categoryData.forEach((category, amount) {
      final double percentage = amount / total;
      sections.add(
        PieChartSectionData(
          color: _chartColors[colorIndex % _chartColors.length],
          value: amount,
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });
    
    return sections;
  }

  // Building the bar chart for daily expenses
  Widget _buildDailyChart() {
    return Consumer<ExpenseViewModel>(
      builder: (context, viewModel, child) {
        return FutureBuilder<Map<DateTime, double>>(
          future: viewModel.getExpensesByDay(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyChartMessage('No data available for history');
            }

            final dailyData = snapshot.data!;
            final sortedDates = dailyData.keys.toList()
              ..sort((a, b) => a.compareTo(b));
            
            // Limit to last 7 days for readability
            final displayDates = sortedDates.length > 7 
                ? sortedDates.sublist(sortedDates.length - 7) 
                : sortedDates;
            
            final maxY = dailyData.values.reduce((max, value) => max > value ? max : value) * 1.2;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses for the last ${displayDates.length} days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: widget.isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final date = displayDates[groupIndex];
                              final amount = dailyData[date]!;
                              return BarTooltipItem(
                                '${DateFormat('dd/MM').format(date)}\n${amount.toStringAsFixed(2)} €',
                                TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= displayDates.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = displayDates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(date),
                                    style: TextStyle(
                                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString() + ' €',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: maxY / 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: false,
                        ),
                        barGroups: List.generate(
                          displayDates.length,
                          (index) {
                            final date = displayDates[index];
                            final amount = dailyData[date]!;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: amount,
                                  color: const Color(0xFF4CD964),
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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

  // Message displayed when there is no data to show
  Widget _buildEmptyChartMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}