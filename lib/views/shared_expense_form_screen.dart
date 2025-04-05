import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/shared_expense.dart';
import '../models/travel_group.dart';
import '../viewmodels/travel_group_viewmodel.dart';

class SharedExpenseFormScreen extends StatefulWidget {
  final String groupId;
  final SharedExpense? expense; // Null pour une nouvelle dépense
  final bool isDarkMode;
  final Function toggleTheme;

  const SharedExpenseFormScreen({
    Key? key,
    required this.groupId,
    this.expense,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<SharedExpenseFormScreen> createState() => _SharedExpenseFormScreenState();
}

class _SharedExpenseFormScreenState extends State<SharedExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = ExpenseCategories.food;
  String _selectedCurrency = 'EUR';
  DateTime _selectedDate = DateTime.now();
  String _selectedPayerId = '';
  SplitType _selectedSplitType = SplitType.equal;
  final Map<String, double> _customAmounts = {};
  final Map<String, double> _percentages = {};

  @override
  void initState() {
    super.initState();
    
    // Initialiser le ViewModel
    Future.microtask(() {
      final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
      viewModel.setCurrentGroup(widget.groupId);
      
      // Si on modifie une dépense existante, initialiser les champs
      if (widget.expense != null) {
        _amountController.text = widget.expense!.amount.toString();
        _descriptionController.text = widget.expense!.description;
        _selectedCategory = widget.expense!.category;
        _selectedCurrency = widget.expense!.currency;
        _selectedDate = widget.expense!.date;
        _selectedPayerId = widget.expense!.payerId;
        _selectedSplitType = widget.expense!.splitType;
        _customAmounts.addAll(widget.expense!.splitAmounts);
        
        // Calculer les pourcentages si nécessaire
        if (_selectedSplitType == SplitType.percentage) {
          widget.expense!.splitAmounts.forEach((memberId, amount) {
            _percentages[memberId] = (amount / widget.expense!.amount) * 100;
          });
        }
      } else {
        // Pour une nouvelle dépense, définir le payeur par défaut
        if (viewModel.currentGroup != null && viewModel.currentGroup!.members.isNotEmpty) {
          _selectedPayerId = viewModel.currentGroup!.members.first.id;
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Méthode pour afficher le sélecteur de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Méthode pour sauvegarder la dépense
  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    
    final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
    final amount = double.parse(_amountController.text);
    
    // Préparer les montants de répartition selon le type choisi
    Map<String, double> splitAmounts = {};
    
    switch (_selectedSplitType) {
      case SplitType.equal:
        if (viewModel.currentGroup != null) {
          final memberIds = viewModel.currentGroup!.members.map((m) => m.id).toList();
          splitAmounts = SharedExpense.createEqualSplit(memberIds, amount);
        }
        break;
      case SplitType.custom:
        splitAmounts = Map.from(_customAmounts);
        break;
      case SplitType.percentage:
        if (viewModel.currentGroup != null) {
          final memberIds = viewModel.currentGroup!.members.map((m) => m.id).toList();
          splitAmounts = SharedExpense.createPercentageSplit(
            memberIds, 
            _percentages, 
            amount
          );
        }
        break;
    }
    
    // Créer ou mettre à jour la dépense partagée
    final sharedExpense = SharedExpense(
      id: widget.expense?.id,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      description: _descriptionController.text,
      currency: _selectedCurrency,
      groupId: widget.groupId,
      payerId: _selectedPayerId,
      splitAmounts: splitAmounts,
      splitType: _selectedSplitType,
    );
    
    if (widget.expense == null) {
      // Ajouter une nouvelle dépense
      viewModel.addSharedExpense(sharedExpense);
    } else {
      // Mettre à jour une dépense existante
      viewModel.updateSharedExpense(sharedExpense);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelGroupViewModel>(
      builder: (context, viewModel, child) {
        final group = viewModel.currentGroup;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.expense == null ? 'Nouvelle dépense' : 'Modifier la dépense'),
            actions: [
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => widget.toggleTheme(),
              ),
            ],
          ),
          body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : (group == null
                  ? Center(child: Text('Groupe non trouvé'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Montant
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Montant',
                                hintText: 'Ex: 25.50',
                                suffixText: _selectedCurrency,
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un montant';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Veuillez entrer un nombre valide';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Ex: Dîner au restaurant',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une description';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Catégorie
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Catégorie',
                              ),
                              items: ExpenseCategories.getAllCategories()
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Devise
                            DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'Devise',
                              ),
                              items: ['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD']
                                  .map((currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCurrency = value;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Date
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                                    Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Payeur
                            Text(
                              'Qui a payé ?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedPayerId.isNotEmpty ? _selectedPayerId : null,
                              decoration: InputDecoration(
                                labelText: 'Payeur',
                              ),
                              items: group.members
                                  .map((member) => DropdownMenuItem(
                                        value: member.id,
                                        child: Text(member.name),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedPayerId = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez sélectionner un payeur';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24),
                            
                            // Type de répartition
                            Text(
                              'Comment répartir la dépense ?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            SegmentedButton<SplitType>(
                              segments: [
                                ButtonSegment(
                                  value: SplitType.equal,
                                  label: Text('Égale'),
                                  icon: Icon(Icons.balance),
                                ),
                                ButtonSegment(
                                  value: SplitType.custom,
                                  label: Text('Personnalisée'),
                                  icon: Icon(Icons.edit),
                                ),
                                ButtonSegment(
                                  value: SplitType.percentage,
                                  label: Text('Pourcentage'),
                                  icon: Icon(Icons.percent),
                                ),
                              ],
                              selected: {_selectedSplitType},
                              onSelectionChanged: (Set<SplitType> newSelection) {
                                setState(() {
                                  _selectedSplitType = newSelection.first;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Afficher les options de répartition selon le type choisi
                            if (_selectedSplitType == SplitType.equal)
                              _buildEqualSplitSection(group),
                            if (_selectedSplitType == SplitType.custom)
                              _buildCustomSplitSection(group),
                            if (_selectedSplitType == SplitType.percentage)
                              _buildPercentageSplitSection(group),
                            
                            SizedBox(height: 32),
                            
                            // Bouton de sauvegarde
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveExpense,
                                child: Text(widget.expense == null ? 'Ajouter la dépense' : 'Mettre à jour'),
                                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
        );
      },
    );
  }

  // Construire la section de répartition égale
  Widget _buildEqualSplitSection(TravelGroup group) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final perPersonAmount = group.members.isNotEmpty ? amount / group.members.length : 0.0;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition égale',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Chaque personne paiera: ${perPersonAmount.toStringAsFixed(2)} $_selectedCurrency'),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                return ListTile(
                  title: Text(member.name),
                  trailing: Text('${perPersonAmount.toStringAsFixed(2)} $_selectedCurrency'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section de répartition personnalisée
  Widget _buildCustomSplitSection(TravelGroup group) {
    // Initialiser les montants personnalisés si nécessaire
    if (_customAmounts.isEmpty) {
      for (var member in group.members) {
        _customAmounts[member.id] = 0.0;
      }
    }
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final currentTotal = _customAmounts.values.fold<double>(0.0, (sum, amount) => sum + amount);
    final remaining = totalAmount - currentTotal;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montants personnalisés',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Montant restant à répartir: ${remaining.toStringAsFixed(2)} $_selectedCurrency',
              style: TextStyle(
                color: remaining < 0 ? Colors.red : (remaining > 0 ? Colors.orange : Colors.green),
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(member.name),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: _customAmounts[member.id]?.toString() ?? '0.0',
                          decoration: InputDecoration(
                            suffixText: _selectedCurrency,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              _customAmounts[member.id] = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section de répartition par pourcentage
  Widget _buildPercentageSplitSection(TravelGroup group) {
    // Initialiser les pourcentages si nécessaire
    if (_percentages.isEmpty) {
      final equalPercentage = group.members.isNotEmpty ? 100.0 / group.members.length : 0.0;
      for (var member in group.members) {
        _percentages[member.id] = equalPercentage;
      }
    }
    
    final totalPercentage = _percentages.values.fold<double>(0.0, (sum, percentage) => sum + percentage);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par pourcentage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Total des pourcentages: ${totalPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: (totalPercentage - 100.0).abs() < 0.1 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                final percentage = _percentages[member.id] ?? 0.0;
                final memberAmount = amount * (percentage / 100.0);
                
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name),
                            Text(
                              '${memberAmount.toStringAsFixed(2)} $_selectedCurrency',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: percentage,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                label: percentage.toStringAsFixed(1),
                                onChanged: (value) {
                                  setState(() {
                                    _percentages[member.id] = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('${percentage.toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}