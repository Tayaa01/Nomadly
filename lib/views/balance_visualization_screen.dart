import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_group.dart';
import '../viewmodels/travel_group_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/debt_flow_chart.dart';

class BalanceVisualizationScreen extends StatefulWidget {
  final String groupId;
  final bool isDarkMode;
  final Function toggleTheme;

  const BalanceVisualizationScreen({
    super.key,
    required this.groupId,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<BalanceVisualizationScreen> createState() =>
      _BalanceVisualizationScreenState();
}

class _BalanceVisualizationScreenState
    extends State<BalanceVisualizationScreen> {
  @override
  void initState() {
    super.initState();

    // Load updated data
    Future.microtask(() async {
      final viewModel = Provider.of<TravelGroupViewModel>(
        context,
        listen: false,
      );

      // First, clean up any potential duplicate settlements using the public method
      await viewModel.cleanupDuplicateSettlements(widget.groupId);

      // Then load the group data and recalculate settlements
      await viewModel.setCurrentGroup(widget.groupId);
      viewModel.calculateSettlements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Balance Visualization',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [], // Remove theme toggle button
      ),
      body: Consumer<TravelGroupViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD964)),
            );
          }

          if (viewModel.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          final group = viewModel.currentGroup;
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return RefreshIndicator(
            color: const Color(0xFF4CD964),
            onRefresh: () async {
              await viewModel.setCurrentGroup(widget.groupId);
              viewModel.calculateSettlements();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceHeader(group),
                  const SizedBox(height: 24),
                  _buildBalanceChart(viewModel, group),
                  const SizedBox(height: 32),
                  _buildDetailedBalanceSection(viewModel, group),
                  const SizedBox(height: 32),
                  if (viewModel.settlements.isNotEmpty) ...[
                    _buildOptimalSettlementsSection(viewModel, group),
                    const SizedBox(height: 32),
                    _buildInteractiveFlowSection(viewModel, group),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final viewModel = Provider.of<TravelGroupViewModel>(
            context,
            listen: false,
          );
          viewModel.calculateSettlements();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settlements recalculated'),
              backgroundColor: Color(0xFF4CD964),
              duration: Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CD964),
        tooltip: 'Recalculate Settlements',
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }

  Widget _buildBalanceHeader(TravelGroup group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance Overview',
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildInfoTile(
                  icon: Icons.people,
                  title: '${group.members.length}',
                  subtitle: 'Members',
                ),
                _buildInfoTile(
                  icon: Icons.receipt_long,
                  title:
                      '${Provider.of<TravelGroupViewModel>(context, listen: false).sharedExpenses.length}',
                  subtitle: 'Expenses',
                ),
                _buildInfoTile(
                  icon: Icons.account_balance_wallet,
                  title:
                      '${Provider.of<TravelGroupViewModel>(context, listen: false).settlements.length}',
                  subtitle: 'Settlements',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4CD964), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChart(TravelGroupViewModel viewModel, TravelGroup group) {
    final balances =
        group.members.map((member) {
          return MapEntry(member, viewModel.getMemberBalance(member.id));
        }).toList();

    balances.sort((a, b) => a.value.compareTo(b.value));

    final maxAbsValue = balances
        .map((e) => e.value.abs())
        .reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxAbsValue * 1.2).ceilToDouble();

    final barGroups =
        balances.asMap().entries.map((entry) {
          final index = entry.key;
          final memberBalance = entry.value;
          final balance = memberBalance.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: balance,
                color:
                    balance >= 0 ? const Color(0xFF4CD964) : Colors.redAccent,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                  bottom: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Member Balances',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Tooltip(
                  message:
                      'Green bars show how much a member should receive, red bars show how much they owe',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline,
                    color:
                        widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: yAxisMax,
                  minY: -yAxisMax,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < balances.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                balances[index].key.name.length > 8
                                    ? '${balances[index].key.name.substring(0, 8)}...'
                                    : balances[index].key.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  widget.isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
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
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(const Color(0xFF4CD964), 'To Receive'),
                  const SizedBox(width: 24),
                  _buildLegendItem(Colors.redAccent, 'To Pay'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBalanceSection(
    TravelGroupViewModel viewModel,
    TravelGroup group,
  ) {
    final balances =
        group.members.map((member) {
          return MapEntry(member, viewModel.getMemberBalance(member.id));
        }).toList();

    balances.sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...balances.map((entry) {
              final member = entry.key;
              final balance = entry.value;
              final isPositive = balance >= 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          isPositive
                              ? const Color(0xFF4CD964)
                              : Colors.redAccent,
                      radius: 20,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                          Text(
                            isPositive
                                ? 'To receive: ${balance.toStringAsFixed(2)} €'
                                : 'To pay: ${(-balance).toStringAsFixed(2)} €',
                            style: TextStyle(
                              color:
                                  isPositive
                                      ? const Color(0xFF4CD964)
                                      : Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color:
                          isPositive
                              ? const Color(0xFF4CD964)
                              : Colors.redAccent,
                      size: 20,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalSettlementsSection(
    TravelGroupViewModel viewModel,
    TravelGroup group,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimal Settlements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ...viewModel.settlements.map((settlement) {
              final fromMember = group.members.firstWhere(
                (m) => m.id == settlement.fromMemberId,
                orElse: () => GroupMember(name: 'Unknown'),
              );
              final toMember = group.members.firstWhere(
                (m) => m.id == settlement.toMemberId,
                orElse: () => GroupMember(name: 'Unknown'),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        settlement.isSettled
                            ? const Color(0xFF4CD964).withOpacity(0.1)
                            : widget.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          settlement.isSettled
                              ? const Color(0xFF4CD964)
                              : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            settlement.isSettled
                                ? const Color(0xFF4CD964)
                                : Colors.orange,
                        radius: 20,
                        child: Icon(
                          settlement.isSettled
                              ? Icons.check
                              : Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: fromMember.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' pays '),
                                  TextSpan(
                                    text: toMember.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${settlement.amount.toStringAsFixed(2)} ${settlement.currency}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    settlement.isSettled
                                        ? const Color(0xFF4CD964)
                                        : Colors.orange,
                              ),
                            ),
                            if (settlement.isSettled) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Settled',
                                style: const TextStyle(
                                  color: Color(0xFF4CD964),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!settlement.isSettled)
                        TextButton(
                          onPressed: () {
                            // Call markSettlementAsSettled but don't request a full refresh
                            viewModel.markSettlementAsSettled(settlement.id);
                            // No need to call setState as the provider will notify listeners
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4CD964),
                            backgroundColor:
                                widget.isDarkMode
                                    ? Colors.black26
                                    : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF4CD964)),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Mark as paid',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveFlowSection(
    TravelGroupViewModel viewModel,
    TravelGroup group,
  ) {
    // Only show non-settled settlements for the visualization
    final activeSettlements =
        viewModel.settlements.where((s) => !s.isSettled).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Money Flow Visualization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              height: 300,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black12 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child:
                  activeSettlements.isEmpty
                      ? Center(
                        child: Text(
                          'All settlements are completed!',
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                        ),
                      )
                      : DebtFlowChart(
                        settlements: viewModel.settlements,
                        members: group.members,
                        isDarkMode: widget.isDarkMode,
                      ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black12 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use this chart:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    'Tap a member to see their money flows',
                  ),
                  _buildInstructionItem('Arrows show payment direction'),
                  _buildInstructionItem('Orange lines are pending payments'),
                  _buildInstructionItem('Green lines are completed payments'),
                  _buildInstructionItem('Line thickness represents amount'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for instruction items
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.arrow_right,
            size: 16,
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for minimum of two integers
  int min(int a, int b) => a < b ? a : b;
}
