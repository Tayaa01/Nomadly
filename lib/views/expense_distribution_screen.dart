import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../viewmodels/travel_group_viewmodel.dart';

class ExpenseDistributionScreen extends StatefulWidget {
  final String groupId;
  final String expenseId;
  final bool isDarkMode;
  final Function toggleTheme;

  const ExpenseDistributionScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<ExpenseDistributionScreen> createState() => _ExpenseDistributionScreenState();
}

class _ExpenseDistributionScreenState extends State<ExpenseDistributionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(context, listen: false).setCurrentGroup(widget.groupId);
    });
  }

  // Add a skeleton loader widget
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF232323),
        highlightColor: const Color(0xFF4CD964).withOpacity(0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header skeleton
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Pie chart skeleton
            Container(
              height: 300,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // List skeleton
            ...List.generate(3, (index) => Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Expense Distribution', // Changed from "Répartition de la dépense"
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
      body: Consumer<TravelGroupViewModel>(builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingSkeleton();
        }

        if (viewModel.errorMessage.isNotEmpty) {
          return Center(child: Text('Error: ${viewModel.errorMessage}')); // Changed from "Erreur"
        }

        final group = viewModel.currentGroup;
        if (group == null) {
          return Center(child: Text('Group not found')); // Changed from "Groupe non trouvé"
        }

        final expense = viewModel.sharedExpenses.firstWhere(
          (e) => e.id == widget.expenseId,
          orElse: () => SharedExpense(
            amount: 0,
            category: '',
            date: DateTime.now(),
            description: 'Expense not found', // Changed from "Dépense non trouvée"
            currency: 'EUR',
            groupId: widget.groupId,
            payerId: '',
            splitAmounts: {},
            splitType: SplitType.equal,
          ),
        );

        if (expense.id != widget.expenseId) {
          return Center(child: Text('Expense not found')); // Changed from "Dépense non trouvée"
        }

        final payer = group.members.firstWhere(
          (m) => m.id == expense.payerId,
          orElse: () => GroupMember(name: 'Unknown'), // Changed from "Inconnu"
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseHeader(expense, payer),
              const SizedBox(height: 24),
              _buildDistributionChart(expense, group),
              const SizedBox(height: 24),
              _buildDistributionList(expense, group),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildExpenseHeader(SharedExpense expense, GroupMember payer) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${expense.amount.toStringAsFixed(2)} ${expense.currency}', // Changed from "Montant"
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paid by: ${payer.name}', // Changed from "Payé par"
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('MM/dd/yyyy').format(expense.date)}', // Changed date format and from "Date"
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Category: ${expense.category}', // Changed from "Catégorie"
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Split type: ${_getSplitTypeText(expense.splitType)}', // Changed from "Type de répartition"
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix potential issues with PieChart rendering
  Widget _buildDistributionChart(SharedExpense expense, TravelGroup group) {
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    // Only create pie sections if there are valid split amounts
    if (expense.splitAmounts.isNotEmpty && expense.amount > 0) {
      int colorIndex = 0;
      expense.splitAmounts.forEach((memberId, amount) {
        // Skip entries with zero amount to avoid division by zero errors
        if (amount > 0) {
          final member = group.members.firstWhere(
            (m) => m.id == memberId,
            orElse: () => GroupMember(name: 'Unknown'),
          );

          final percentage = (amount / expense.amount) * 100;
          sections.add(
            PieChartSectionData(
              color: colors[colorIndex % colors.length],
              value: amount,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              badgeWidget: _Badge(member.name[0].toUpperCase()),
              badgePositionPercentageOffset: 1.1,
            ),
          );
          colorIndex++;
        }
      });
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: sections.isEmpty 
        ? Center(
            child: Text(
              'No split data available for visualization',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          )
        : PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(enabled: true),
            ),
          ),
    );
  }

  Widget _buildDistributionList(SharedExpense expense, TravelGroup group) {
    final List<MapEntry<String, double>> sortedEntries = expense.splitAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedEntries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final member = group.members.firstWhere(
            (m) => m.id == entry.key,
            orElse: () => GroupMember(name: 'Unknown'), // Changed from "Inconnu"
          );
          final percentage = (entry.value / expense.amount) * 100;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CD964),
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member.name,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${percentage.toStringAsFixed(1)}% of total', // Changed from "du total"
              style: TextStyle(color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
            trailing: Text(
              '${entry.value.toStringAsFixed(2)} ${expense.currency}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CD964),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSplitTypeText(SplitType splitType) {
    switch (splitType) {
      case SplitType.equal:
        return 'Equal split'; // Changed from "Répartition égale"
      case SplitType.custom:
        return 'Custom amounts'; // Changed from "Montants personnalisés"
      case SplitType.percentage:
        return 'Percentages'; // Changed from "Pourcentages"
      case SplitType.weighted:
        return 'Weighted split'; // Changed from "Inconnu"
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}