import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../viewmodels/travel_group_viewmodel.dart';
import 'shared_expense_form_screen.dart';
import 'balance_visualization_screen.dart';
import 'expense_distribution_screen.dart';

// Update UI elements and translate French to English
class TravelGroupDetailScreen extends StatefulWidget {
  final String groupId;
  final bool isDarkMode;
  final Function toggleTheme;

  const TravelGroupDetailScreen({
    super.key,
    required this.groupId,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<TravelGroupDetailScreen> createState() =>
      _TravelGroupDetailScreenState();
}

// Improve TabController handling
class _TravelGroupDetailScreenState extends State<TravelGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _memberNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to update state when tab changes
    _tabController.addListener(() {
      // Only perform actions when the tab change is completed
      if (!_tabController.indexIsChanging) {
        // If the new tab is the settlements tab (index 2), recalculate settlements
        if (_tabController.index == 2) {
          Provider.of<TravelGroupViewModel>(
            context,
            listen: false,
          ).calculateSettlements();
        }

        setState(() {});
      }
    });

    // Load group data
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(
        context,
        listen: false,
      ).setCurrentGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  // Show dialog to add a new member - Translated from French
  void _showAddMemberDialog() {
    _memberNameController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Add Member', // Changed from "Ajouter un membre"
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _memberNameController,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Member Name', // Changed from "Nom du membre"
                  hintText: 'Ex: John', // Changed from "Ex: Jean"
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: const Color(0xFF4CD964).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4CD964),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name'; // Changed from "Veuillez entrer un nom"
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel', // Changed from "Annuler"
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addNewMember();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CD964),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add'), // Changed from "Ajouter"
              ),
            ],
          ),
    );
  }

  // Add a new member to the group
  void _addNewMember() {
    final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);

    final newMember = GroupMember(name: _memberNameController.text);

    viewModel.addMemberToCurrentGroup(newMember);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelGroupViewModel>(
      builder: (context, viewModel, child) {
        final group = viewModel.currentGroup;

        return Scaffold(
          backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            title: Text(
              group?.name ??
                  'Group Details', // Changed from "Détails du groupe"
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Remove theme toggle button
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4CD964),
              unselectedLabelColor:
                  widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              indicatorColor: const Color(0xFF4CD964),
              tabs: [
                Tab(text: 'Members'), // Changed from "Membres"
                Tab(text: 'Expenses'), // Changed from "Dépenses"
                Tab(text: 'Settlements'), // Changed from "Règlements"
              ],
            ),
          ),
          body:
              viewModel.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CD964)),
                  )
                  : (viewModel.errorMessage.isNotEmpty
                      ? Center(
                        child: Text(
                          viewModel.errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : (group == null
                          ? Center(
                            child: Text('Group not found'),
                          ) // Changed from "Groupe non trouvé"
                          : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMembersTab(viewModel, group),
                              _buildExpensesTab(viewModel, group),
                              _buildSettlementsTab(viewModel, group),
                            ],
                          ))),
          floatingActionButton: _buildFloatingActionButton(
            viewModel,
            _tabController.index,
          ),
        );
      },
    );
  }

  // Build the members tab
  Widget _buildMembersTab(TravelGroupViewModel viewModel, TravelGroup group) {
    return ListView.builder(
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        final balance = viewModel.getMemberBalance(member.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CD964),
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
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
              balance > 0
                  ? 'To receive: ${balance.toStringAsFixed(2)} €' // Changed from "Doit recevoir"
                  : balance < 0
                  ? 'To pay: ${(-balance).toStringAsFixed(2)} €' // Changed from "Doit payer"
                  : 'Balance: 0.00 €', // Changed from "Solde"
              style: TextStyle(
                color:
                    balance > 0
                        ? Colors.green
                        : balance < 0
                        ? Colors.red
                        : widget.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[700],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Confirm member deletion
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor:
                            widget.isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Delete Member', // Changed from "Supprimer le membre"
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to remove ${member.name} from the group?', // Changed from French
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ), // Changed from "Annuler"
                          ),
                          ElevatedButton(
                            onPressed: () {
                              viewModel.removeMemberFromCurrentGroup(member.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Delete'), // Changed from "Supprimer"
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Build the expenses tab
  Widget _buildExpensesTab(TravelGroupViewModel viewModel, TravelGroup group) {
    if (viewModel.sharedExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No shared expenses', // Changed from "Aucune dépense partagée"
              style: TextStyle(
                fontSize: 18,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddExpense(group),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add an expense',
              ), // Changed from "Ajouter une dépense"
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
          orElse: () => GroupMember(name: 'Unknown'), // Changed from "Inconnu"
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 4,
          child: InkWell(
            onTap: () => _navigateToEditExpense(group, expense),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    expense.description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid by: ${payer.name}', // Changed from "Payé par"
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Date: ${DateFormat('MM/dd/yyyy').format(expense.date)}', // Changed date format
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Split type: ${_getSplitTypeText(expense.splitType)}', // Changed from "Type de partage"
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 90, // Fixed width to prevent overflow
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CD964),
                            fontSize: 14, // Slightly smaller font
                          ),
                          overflow:
                              TextOverflow.ellipsis, // Prevent text overflow
                        ),
                        // Use a smaller, more compact delete button
                        GestureDetector(
                          onTap: () {
                            // Existing delete dialog code can remain the same
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    backgroundColor:
                                        widget.isDarkMode
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text(
                                      'Delete Expense', // Changed from "Supprimer la dépense"
                                      style: TextStyle(
                                        color:
                                            widget.isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete this expense?', // Changed from French
                                      style: TextStyle(
                                        color:
                                            widget.isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.grey),
                                        ), // Changed from "Annuler"
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          viewModel.deleteSharedExpense(
                                            expense.id,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Delete',
                                        ), // Changed from "Supprimer"
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Delete', // More compact than an icon
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          () => _navigateToExpenseDistribution(group, expense),
                      icon: const Icon(
                        Icons.pie_chart,
                        size: 16,
                        color: Color(0xFF4CD964),
                      ),
                      label: Text(
                        'View distribution', // Changed from "Voir la répartition"
                        style: const TextStyle(color: Color(0xFF4CD964)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
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

  // Build the settlements tab
  Widget _buildSettlementsTab(
    TravelGroupViewModel viewModel,
    TravelGroup group,
  ) {
    if (viewModel.settlements.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No settlements to make', // Changed from "Aucun règlement à effectuer"
                style: TextStyle(
                  fontSize: 18,
                  color:
                      widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToBalanceVisualization(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.bar_chart),
                label: const Text(
                  'Visualize Balances',
                ), // Changed from "Visualiser les soldes"
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the single button
            children: [
              // Remove the Recalculate button and keep only the Balance button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToBalanceVisualization(group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ), // Slightly larger now
                  ),
                  icon: const Icon(
                    Icons.bar_chart,
                    size: 18,
                  ), // Slightly larger icon
                  label: const Text(
                    'Visualize Balances', // Use full text now that we have more space
                    style: TextStyle(fontSize: 14), // Slightly larger text
                  ),
                ),
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
                orElse:
                    () =>
                        GroupMember(name: 'Unknown'), // Changed from "Inconnu"
              );
              final toMember = group.members.firstWhere(
                (m) => m.id == settlement.toMemberId,
                orElse:
                    () =>
                        GroupMember(name: 'Unknown'), // Changed from "Inconnu"
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color:
                    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        settlement.isSettled ? Colors.green : Colors.orange,
                    child: Icon(
                      settlement.isSettled ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${fromMember.name} owes ${toMember.name}', // Changed from "doit payer"
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    settlement.isSettled
                        ? 'Settled on ${DateFormat('MM/dd/yyyy').format(settlement.date)}' // Changed from "Réglé le"
                        : 'Pending settlement', // Changed from "En attente de règlement"
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[700],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${settlement.amount.toStringAsFixed(2)} ${settlement.currency}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF4CD964),
                        ),
                      ),
                      if (!settlement.isSettled)
                        TextButton(
                          onPressed:
                              () => viewModel.markSettlementAsSettled(
                                settlement.id,
                              ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4CD964),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mark as settled',
                          ), // Changed from "Marquer comme réglé"
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

  // Build the floating action button according to the active tab
  Widget _buildFloatingActionButton(
    TravelGroupViewModel viewModel,
    int tabIndex,
  ) {
    // Make sure we have a valid group before showing expense-related FABs
    if (viewModel.currentGroup == null && tabIndex == 1) {
      return Container(); // No FAB if there's no group
    }

    switch (tabIndex) {
      case 0: // Members tab
        return FloatingActionButton(
          onPressed: _showAddMemberDialog,
          backgroundColor: const Color(0xFF4CD964),
          tooltip: 'Add a member',
          child: const Icon(Icons.person_add, color: Colors.black),
        );
      case 1: // Expenses tab
        return FloatingActionButton(
          onPressed:
              viewModel.currentGroup != null
                  ? () => _navigateToAddExpense(viewModel.currentGroup!)
                  : null,
          backgroundColor: const Color(0xFF4CD964),
          tooltip: 'Add an expense',
          child: const Icon(Icons.add, color: Colors.black),
        );
      default:
        return Container(); // No button for the Settlements tab
    }
  }

  // Navigate to add expense screen
  void _navigateToAddExpense(TravelGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SharedExpenseFormScreen(
              groupId: group.id,
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    );
  }

  // Navigate to edit expense screen
  void _navigateToEditExpense(TravelGroup group, SharedExpense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SharedExpenseFormScreen(
              groupId: group.id,
              expense: expense,
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    );
  }

  // Navigate to balance visualization screen
  void _navigateToBalanceVisualization(TravelGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BalanceVisualizationScreen(
              groupId: group.id,
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    );
  }

  // Navigate to expense distribution screen
  void _navigateToExpenseDistribution(
    TravelGroup group,
    SharedExpense expense,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExpenseDistributionScreen(
              groupId: group.id,
              expenseId: expense.id,
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    );
  }

  // Get text for split type
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
