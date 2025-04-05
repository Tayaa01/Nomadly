import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../viewmodels/travel_group_viewmodel.dart';
import 'shared_expense_form_screen.dart';
import 'balance_visualization_screen.dart';
import 'expense_distribution_screen.dart';
import 'settlement_management_screen.dart';

class TravelGroupDetailScreen extends StatefulWidget {
  final String groupId;
  final bool isDarkMode;
  final Function toggleTheme;

  const TravelGroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<TravelGroupDetailScreen> createState() => _TravelGroupDetailScreenState();
}

class _TravelGroupDetailScreenState extends State<TravelGroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _memberNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les données du groupe
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(context, listen: false).setCurrentGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  // Afficher le dialogue pour ajouter un nouveau membre
  void _showAddMemberDialog() {
    _memberNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un membre'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _memberNameController,
            decoration: InputDecoration(
              labelText: 'Nom du membre',
              hintText: 'Ex: Jean',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _addNewMember();
                Navigator.pop(context);
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Ajouter un nouveau membre au groupe
  void _addNewMember() {
    final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
    
    final newMember = GroupMember(
      name: _memberNameController.text,
    );
    
    viewModel.addMemberToCurrentGroup(newMember);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelGroupViewModel>(
      builder: (context, viewModel, child) {
        final group = viewModel.currentGroup;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(group?.name ?? 'Détails du groupe'),
            actions: [
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => widget.toggleTheme(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Membres'),
                Tab(text: 'Dépenses'),
                Tab(text: 'Règlements'),
              ],
            ),
          ),
          body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : (viewModel.errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        viewModel.errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : (group == null
                      ? Center(child: Text('Groupe non trouvé'))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMembersTab(viewModel, group),
                            _buildExpensesTab(viewModel, group),
                            _buildSettlementsTab(viewModel, group),
                          ],
                        ))),
          floatingActionButton: _buildFloatingActionButton(viewModel, _tabController.index),
        );
      },
    );
  }

  // Construire l'onglet des membres
  Widget _buildMembersTab(TravelGroupViewModel viewModel, TravelGroup group) {
    return ListView.builder(
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        final balance = viewModel.getMemberBalance(member.id);
        
        return ListTile(
          leading: CircleAvatar(
            child: Text(member.name[0].toUpperCase()),
            backgroundColor: Colors.blue,
          ),
          title: Text(member.name),
          subtitle: Text(
            balance > 0
                ? 'Doit recevoir: ${balance.toStringAsFixed(2)} €'
                : balance < 0
                    ? 'Doit payer: ${(-balance).toStringAsFixed(2)} €'
                    : 'Solde: 0.00 €',
            style: TextStyle(
              color: balance > 0
                  ? Colors.green
                  : balance < 0
                      ? Colors.red
                      : null,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Confirmer la suppression du membre
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Supprimer le membre'),
                  content: Text('Êtes-vous sûr de vouloir supprimer ${member.name} du groupe ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        viewModel.removeMemberFromCurrentGroup(member.id);
                        Navigator.pop(context);
                      },
                      child: Text('Supprimer'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Construire l'onglet des dépenses
  Widget _buildExpensesTab(TravelGroupViewModel viewModel, TravelGroup group) {
    if (viewModel.sharedExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune dépense partagée',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddExpense(group),
              icon: Icon(Icons.add),
              label: Text('Ajouter une dépense'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: viewModel.sharedExpenses.length,
      itemBuilder: (context, index) {
        final expense = viewModel.sharedExpenses[index];
        final payer = group.members.firstWhere(
          (m) => m.id == expense.payerId,
          orElse: () => GroupMember(name: 'Inconnu'),
        );
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _navigateToEditExpense(group, expense),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    expense.description,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payé par: ${payer.name}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Type de partage: ${_getSplitTypeText(expense.splitType)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20),
                        onPressed: () {
                          // Confirmer la suppression de la dépense
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Supprimer la dépense'),
                              content: Text('Êtes-vous sûr de vouloir supprimer cette dépense ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    viewModel.deleteSharedExpense(expense.id);
                                    Navigator.pop(context);
                                  },
                                  child: Text('Supprimer'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _navigateToExpenseDistribution(group, expense),
                      icon: Icon(Icons.pie_chart, size: 16),
                      label: Text('Voir la répartition'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construire l'onglet des règlements
  Widget _buildSettlementsTab(TravelGroupViewModel viewModel, TravelGroup group) {
    if (viewModel.settlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun règlement à effectuer',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.calculateSettlements(),
              icon: Icon(Icons.refresh),
              label: Text('Calculer les règlements'),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToBalanceVisualization(group),
              icon: Icon(Icons.bar_chart),
              label: Text('Visualiser les soldes'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => viewModel.calculateSettlements(),
                icon: Icon(Icons.refresh),
                label: Text('Recalculer'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _navigateToBalanceVisualization(group),
                    icon: Icon(Icons.bar_chart),
                    label: Text('Visualiser les soldes'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettlementManagementScreen(
                          groupId: group.id,
                          isDarkMode: widget.isDarkMode,
                          toggleTheme: widget.toggleTheme,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.account_balance_wallet),
                    label: Text('Gérer les règlements'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
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
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(settlement.isSettled ? Icons.check : Icons.arrow_forward),
                    backgroundColor: settlement.isSettled ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    '${fromMember.name} doit payer ${toMember.name}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    settlement.isSettled ? 'Réglé le ${DateFormat('dd/MM/yyyy').format(settlement.date)}' : 'En attente de règlement',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${settlement.amount.toStringAsFixed(2)} ${settlement.currency}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!settlement.isSettled)
                        TextButton(
                          onPressed: () => viewModel.markSettlementAsSettled(settlement.id),
                          child: Text('Marquer comme réglé'),
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

  // Construire le bouton flottant en fonction de l'onglet actif
  Widget _buildFloatingActionButton(TravelGroupViewModel viewModel, int tabIndex) {
    switch (tabIndex) {
      case 0: // Onglet Membres
        return FloatingActionButton(
          onPressed: _showAddMemberDialog,
          child: Icon(Icons.person_add),
          tooltip: 'Ajouter un membre',
        );
      case 1: // Onglet Dépenses
        return FloatingActionButton(
          onPressed: () => _navigateToAddExpense(viewModel.currentGroup!),
          child: Icon(Icons.add),
          tooltip: 'Ajouter une dépense',
        );
      default:
        return Container(); // Pas de bouton pour l'onglet Règlements
    }
  }

  // Naviguer vers l'écran d'ajout de dépense
  void _navigateToAddExpense(TravelGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedExpenseFormScreen(
          groupId: group.id,
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );
  }

  // Naviguer vers l'écran de modification de dépense
  void _navigateToEditExpense(TravelGroup group, SharedExpense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedExpenseFormScreen(
          groupId: group.id,
          expense: expense,
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );
  }
  
  // Naviguer vers l'écran de visualisation des soldes
  void _navigateToBalanceVisualization(TravelGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalanceVisualizationScreen(
          groupId: group.id,
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );
  }

  // Naviguer vers l'écran de visualisation de la répartition des dépenses
  void _navigateToExpenseDistribution(TravelGroup group, SharedExpense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDistributionScreen(
          groupId: group.id,
          expenseId: expense.id,
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );
  }

  // Obtenir le texte correspondant au type de répartition
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