import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../viewmodels/travel_group_viewmodel.dart';

class ExpenseDistributionScreen extends StatefulWidget {
  final String groupId;
  final String expenseId;
  final bool isDarkMode;
  final Function toggleTheme;

  const ExpenseDistributionScreen({
    Key? key,
    required this.groupId,
    required this.expenseId,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Répartition de la dépense'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      body: Consumer<TravelGroupViewModel>(builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage.isNotEmpty) {
          return Center(child: Text('Erreur: ${viewModel.errorMessage}'));
        }

        final group = viewModel.currentGroup;
        if (group == null) {
          return Center(child: Text('Groupe non trouvé'));
        }

        final expense = viewModel.sharedExpenses.firstWhere(
          (e) => e.id == widget.expenseId,
          orElse: () => SharedExpense(
            amount: 0,
            category: '',
            date: DateTime.now(),
            description: 'Dépense non trouvée',
            currency: 'EUR',
            groupId: widget.groupId,
            payerId: '',
            splitAmounts: {},
            splitType: SplitType.equal,
          ),
        );

        if (expense.id != widget.expenseId) {
          return Center(child: Text('Dépense non trouvée'));
        }

        final payer = group.members.firstWhere(
          (m) => m.id == expense.payerId,
          orElse: () => GroupMember(name: 'Inconnu'),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseHeader(expense, payer),
              SizedBox(height: 24),
              _buildDistributionChart(expense, group),
              SizedBox(height: 24),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Montant: ${expense.amount.toStringAsFixed(2)} ${expense.currency}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Payé par: ${payer.name}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(expense.date)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Catégorie: ${expense.category}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Type de répartition: ${_getSplitTypeText(expense.splitType)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

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

    int colorIndex = 0;
    expense.splitAmounts.forEach((memberId, amount) {
      final member = group.members.firstWhere(
        (m) => m.id == memberId,
        orElse: () => GroupMember(name: 'Inconnu'),
      );

      final percentage = (amount / expense.amount) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          badgeWidget: _Badge(member.name[0].toUpperCase()),
          badgePositionPercentageOffset: 1.1,
        ),
      );
      colorIndex++;
    });

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: PieChart(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: sortedEntries.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final member = group.members.firstWhere(
            (m) => m.id == entry.key,
            orElse: () => GroupMember(name: 'Inconnu'),
          );
          final percentage = (entry.value / expense.amount) * 100;

          return ListTile(
            leading: CircleAvatar(
              child: Text(member.name[0].toUpperCase()),
              backgroundColor: Colors.blue,
            ),
            title: Text(member.name),
            subtitle: Text('${percentage.toStringAsFixed(1)}% du total'),
            trailing: Text(
              '${entry.value.toStringAsFixed(2)} ${expense.currency}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  String _getSplitTypeText(SplitType splitType) {
    switch (splitType) {
      case SplitType.equal:
        return 'Répartition égale';
      case SplitType.custom:
        return 'Montants personnalisés';
      case SplitType.percentage:
        return 'Pourcentages';
      default:
        return 'Inconnu';
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
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}