import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../models/settlement_method.dart';
import '../viewmodels/travel_group_viewmodel.dart';
import '../widgets/app_drawer.dart'; // Add this import

class SettlementManagementScreen extends StatefulWidget {
  final String groupId;
  final bool isDarkMode;
  final Function toggleTheme;

  const SettlementManagementScreen({
    Key? key,
    required this.groupId,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<SettlementManagementScreen> createState() => _SettlementManagementScreenState();
}

class _SettlementManagementScreenState extends State<SettlementManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger les données du groupe
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(context, listen: false).setCurrentGroup(widget.groupId);
      Provider.of<TravelGroupViewModel>(context, listen: false).calculateSettlements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des règlements'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Règlements optimaux'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/travel-groups'), // Add drawer
      body: Consumer<TravelGroupViewModel>(
        builder: (context, viewModel, child) {
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOptimalSettlementsTab(viewModel, group),
              _buildSettlementHistoryTab(viewModel, group),
            ],
          );
        },
      ),
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

  Widget _buildOptimalSettlementsTab(TravelGroupViewModel viewModel, TravelGroup group) {
    if (viewModel.settlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tous les comptes sont équilibrés !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Il n\'y a pas de règlements à effectuer.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Wrap the content in a SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Règlements optimaux',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Voici les transactions minimales nécessaires pour équilibrer les comptes:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          _buildSettlementsList(viewModel, group),
        ],
      ),
    );
  }

  Widget _buildSettlementHistoryTab(TravelGroupViewModel viewModel, TravelGroup group) {
    final settledSettlements = viewModel.settlements.where((s) => s.isSettled).toList();
    
    if (settledSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun règlement effectué',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'L\'historique des règlements s\'affichera ici.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Wrap the content in a SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des règlements',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: settledSettlements.length,
            itemBuilder: (context, index) {
              final settlement = settledSettlements[index];
              final fromMember = group.members.firstWhere(
                (m) => m.id == settlement.fromMemberId,
                orElse: () => GroupMember(name: 'Inconnu'),
              );
              final toMember = group.members.firstWhere(
                (m) => m.id == settlement.toMemberId,
                orElse: () => GroupMember(name: 'Inconnu'),
              );

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(
                    '${fromMember.name} → ${toMember.name}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Prevent overflow in title
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${settlement.amount.toStringAsFixed(2)} ${settlement.currency}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Prevent overflow in subtitle
                      ),
                      Text(
                        'Réglé le ${DateFormat('dd/MM/yyyy').format(settlement.date)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (settlement.method != SettlementMethod.other)
                        Text(
                          'Méthode: ${settlement.method.displayName}',
                          style: TextStyle(fontSize: 12),
                        ),
                      if (settlement.notes != null && settlement.notes!.isNotEmpty)
                        Text(
                          'Note: ${settlement.notes}',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementsList(TravelGroupViewModel viewModel, TravelGroup group) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: viewModel.settlements.length,
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

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: settlement.isSettled ? Colors.green : Colors.orange,
              child: Icon(
                settlement.isSettled ? Icons.check : Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${fromMember.name} doit payer ${toMember.name}',
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Prevent overflow in title
            ),
            subtitle: Text(
              '${settlement.amount.toStringAsFixed(2)} ${settlement.currency}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Prevent overflow in subtitle
            ),
            trailing: settlement.isSettled
                ? Chip(
                    label: Text('Réglé'),
                    backgroundColor: Colors.green[100],
                    labelStyle: TextStyle(color: Colors.green[800]),
                  )
                : ElevatedButton(
                    onPressed: () => _showSettlementDialog(settlement, fromMember, toMember),
                    child: Text('Marquer comme réglé'),
                  ),
          ),
        );
      },
    );
  }

  void _showSettlementDialog(Settlement settlement, GroupMember fromMember, GroupMember toMember) {
    SettlementMethod selectedMethod = SettlementMethod.other;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer le règlement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fromMember.name} a payé ${settlement.amount.toStringAsFixed(2)} ${settlement.currency} à ${toMember.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Méthode de paiement:'),
              SizedBox(height: 8),
              DropdownButtonFormField<SettlementMethod>(
                value: selectedMethod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: SettlementMethod.values
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedMethod = value;
                  }
                },
              ),
              SizedBox(height: 16),
              Text('Note (optionnelle):'),
              SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Ex: Remboursement du dîner',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
              viewModel.markSettlementAsSettled(
                settlement.id,
                method: selectedMethod,
                notes: noteController.text.isNotEmpty ? noteController.text : null,
              );
              Navigator.pop(context);
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}