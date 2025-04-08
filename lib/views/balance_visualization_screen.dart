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
    Key? key,
    required this.groupId,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<BalanceVisualizationScreen> createState() => _BalanceVisualizationScreenState();
}

class _BalanceVisualizationScreenState extends State<BalanceVisualizationScreen> {
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
        title: Text('Visualisation des soldes'),
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

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soldes des membres',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              _buildBalanceChart(viewModel, group),
              SizedBox(height: 32),
              Text(
                'Détail des soldes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildBalanceList(viewModel, group),
              SizedBox(height: 32),
              if (viewModel.settlements.isNotEmpty) ...[  
                Text(
                  'Règlements optimaux',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildSettlementsList(viewModel, group),
                SizedBox(height: 32),
                Text(
                  'Visualisation interactive des flux d\'argent',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildInteractiveFlowChart(viewModel, group),
              ],
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
          viewModel.calculateSettlements();
        },
        child: Icon(Icons.refresh),
        tooltip: 'Recalculer les règlements',
      ),
    );
  }

  Widget _buildBalanceChart(TravelGroupViewModel viewModel, TravelGroup group) {
    final balances = group.members.map((member) {
      return MapEntry(member, viewModel.getMemberBalance(member.id));
    }).toList();

    // Trier par solde
    balances.sort((a, b) => a.value.compareTo(b.value));

    final barGroups = balances.asMap().entries.map((entry) {
      final index = entry.key;
      final memberBalance = entry.value;
      final balance = memberBalance.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: balance,
            color: balance >= 0 ? Colors.green : Colors.red,
            width: 20,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(6),
              bottom: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          maxY: balances.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b) * 1.2,
          minY: -balances.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b) * 1.2,
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
                        balances[index].key.name.substring(0, min(balances[index].key.name.length, 8)),
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return Text('');
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
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildBalanceList(TravelGroupViewModel viewModel, TravelGroup group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: group.members.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final member = group.members[index];
          final balance = viewModel.getMemberBalance(member.id);

          return ListTile(
            leading: CircleAvatar(
              child: Text(member.name[0].toUpperCase()),
              backgroundColor: balance >= 0 ? Colors.green : Colors.red,
            ),
            title: Text(member.name),
            subtitle: Text(
              balance >= 0
                  ? 'Doit recevoir: ${balance.toStringAsFixed(2)} €'
                  : 'Doit payer: ${(-balance).toStringAsFixed(2)} €',
            ),
            trailing: Icon(
              balance >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettlementsList(TravelGroupViewModel viewModel, TravelGroup group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: viewModel.settlements.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final settlement = viewModel.settlements[index];
          final fromMember = group.members.firstWhere(
            (m) => m.id == settlement.fromMemberId,
            orElse: () => GroupMember(name: 'Inconnu'),
          );
          final toMember = group.members.firstWhere(
            (m) => m.id == settlement.toMemberId,
            orElse: () => GroupMember(name: 'Inconnu'),
          );

          return ListTile(
            leading: CircleAvatar(
              child: Icon(settlement.isSettled ? Icons.check : Icons.arrow_forward),
              backgroundColor: settlement.isSettled ? Colors.green : Colors.orange,
            ),
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                children: [
                  TextSpan(text: fromMember.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' doit payer '),
                  TextSpan(text: toMember.name, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: Text(
              '${settlement.amount.toStringAsFixed(2)} €',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: settlement.isSettled
                ? null
                : () {
                    viewModel.markSettlementAsSettled(settlement.id);
                  },
          );
        },
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
  
  // Construire le graphique interactif des flux d'argent
  Widget _buildInteractiveFlowChart(TravelGroupViewModel viewModel, TravelGroup group) {
    // Ne montrer que les règlements non réglés pour la visualisation interactive
    viewModel.settlements.where((s) => !s.isSettled).toList();
    
    return Column(
      children: [
        Container(
          height: 400, // Plus grand pour une meilleure visualisation
          child: DebtFlowChart(
            settlements: viewModel.settlements, // Tous les règlements pour voir aussi les réglés
            members: group.members,
            isDarkMode: widget.isDarkMode,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment utiliser ce graphique :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• Touchez un membre pour voir ses flux d\'argent'),
                Text('• Les flèches indiquent la direction du paiement'),
                Text('• Les lignes orange représentent les flux sélectionnés'),
                Text('• Les lignes grises sont les règlements déjà effectués'),
                Text('• L\'épaisseur des lignes est proportionnelle au montant'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}