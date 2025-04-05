import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/shared_expense.dart' as shared_expense_model;
import '../models/travel_group.dart';
import '../models/expense_split_options.dart';
import '../viewmodels/travel_group_viewmodel.dart';

class SharedExpenseFormScreen extends StatefulWidget {
  final String groupId;
  final shared_expense_model.SharedExpense? expense; // Null pour une nouvelle dépense
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
  late ExpenseSplitOptions _splitOptions;
  bool _splitOptionsInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le ViewModel
    Future.microtask(() {
      final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
      viewModel.setCurrentGroup(widget.groupId);
      
      // Initialiser les options de répartition
      if (viewModel.currentGroup != null) {
        final memberIds = viewModel.currentGroup!.members.map((m) => m.id).toList();
        _splitOptions = ExpenseSplitOptions.initializeForMembers(memberIds);
        _splitOptionsInitialized = true;
      }
      
      // Si on modifie une dépense existante, initialiser les champs
      if (widget.expense != null) {
        _amountController.text = widget.expense!.amount.toString();
        _descriptionController.text = widget.expense!.description;
        _selectedCategory = widget.expense!.category;
        _selectedCurrency = widget.expense!.currency;
        _selectedDate = widget.expense!.date;
        _selectedPayerId = widget.expense!.payerId;
        // Convertir le SplitType de shared_expense.dart vers le SplitType de expense_split_options.dart
        _selectedSplitType = SplitType.values.firstWhere(
          (type) => type.toString().split('.').last == widget.expense!.splitType.toString().split('.').last,
          orElse: () => SplitType.equal,
        );
        
        // Initialiser les options de répartition à partir de la dépense existante
        if (viewModel.currentGroup != null) {
          final memberIds = viewModel.currentGroup!.members.map((m) => m.id).toList();
          Map<String, bool> includedMembers = {};
          Map<String, double> customAmounts = {};
          Map<String, double> percentages = {};
          Map<String, int> weights = {};
          
          // Déterminer quels membres sont inclus dans la répartition
          for (var memberId in memberIds) {
            includedMembers[memberId] = widget.expense!.splitAmounts.containsKey(memberId) && 
                                       widget.expense!.splitAmounts[memberId]! > 0;
            customAmounts[memberId] = widget.expense!.splitAmounts[memberId] ?? 0.0;
            
            // Calculer les pourcentages si nécessaire
            if (_selectedSplitType == SplitType.percentage) {
              percentages[memberId] = widget.expense!.splitAmounts.containsKey(memberId) ?
                  (widget.expense!.splitAmounts[memberId]! / widget.expense!.amount) * 100 : 0.0;
            } else {
              percentages[memberId] = 0.0;
            }
            
            // Initialiser les poids à 1 par défaut
            weights[memberId] = 1;
          }
          
          _splitOptions = ExpenseSplitOptions(
            includedMembers: includedMembers,
            customAmounts: customAmounts,
            percentages: percentages,
            weights: weights,
          );
          _splitOptionsInitialized = true;
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
    if (!_splitOptionsInitialized) return;
    
    final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
    final amount = double.parse(_amountController.text);
    
    // Calculer les montants de répartition en utilisant les options avancées
    Map<String, double> splitAmounts = _splitOptions.calculateSplitAmounts(_selectedSplitType, amount);
    
    // Créer ou mettre à jour la dépense partagée
    final sharedExpense = shared_expense_model.SharedExpense(
      id: widget.expense?.id,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      description: _descriptionController.text,
      currency: _selectedCurrency,
      groupId: widget.groupId,
      payerId: _selectedPayerId,
      splitAmounts: splitAmounts,
      splitType: shared_expense_model.SplitType.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedSplitType.toString().split('.').last,
        orElse: () => shared_expense_model.SplitType.equal,
      ),
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
    if (!_splitOptionsInitialized) return SizedBox();
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final includedMembers = _splitOptions.includedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    final perPersonAmount = includedMembers.isNotEmpty ? amount / includedMembers.length : 0.0;
    
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
            Text(
              includedMembers.isNotEmpty
                  ? 'Chaque personne incluse paiera: ${perPersonAmount.toStringAsFixed(2)} $_selectedCurrency'
                  : 'Aucun membre inclus dans la répartition',
              style: TextStyle(
                color: includedMembers.isEmpty ? Colors.red : null,
                fontWeight: includedMembers.isEmpty ? FontWeight.bold : null,
              ),
            ),
            SizedBox(height: 16),
            Text('Qui participe à cette dépense ?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                final isIncluded = _splitOptions.includedMembers[member.id] ?? false;
                
                return CheckboxListTile(
                  title: Text(member.name),
                  subtitle: isIncluded
                      ? Text('${perPersonAmount.toStringAsFixed(2)} $_selectedCurrency')
                      : Text('Non inclus', style: TextStyle(fontStyle: FontStyle.italic)),
                  value: isIncluded,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        final updatedIncludedMembers = Map<String, bool>.from(_splitOptions.includedMembers);
                        updatedIncludedMembers[member.id] = value;
                        _splitOptions = _splitOptions.copyWith(includedMembers: updatedIncludedMembers);
                      });
                    }
                  },
                  secondary: CircleAvatar(
                    child: Text(member.name[0].toUpperCase()),
                    backgroundColor: isIncluded ? Colors.blue : Colors.grey,
                  ),
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
    if (!_splitOptionsInitialized) return SizedBox();
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final currentTotal = _splitOptions.customAmounts.entries
        .where((entry) => _splitOptions.includedMembers[entry.key] ?? false)
        .fold<double>(0.0, (sum, entry) => sum + entry.value);
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Visualisation en temps réel de la répartition
            _buildDistributionVisualizer(group, totalAmount),
            SizedBox(height: 16),
            // Indicateur de montant restant
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: remaining < 0 ? Colors.red.withOpacity(0.1) : 
                       (remaining > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    remaining < 0 ? Icons.error_outline : 
                    (remaining > 0 ? Icons.warning_amber_outlined : Icons.check_circle_outline),
                    color: remaining < 0 ? Colors.red : 
                           (remaining > 0 ? Colors.orange : Colors.green),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Montant restant à répartir: ${remaining.toStringAsFixed(2)} $_selectedCurrency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? Colors.red : 
                               (remaining > 0 ? Colors.orange : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Qui participe à cette dépense ?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            // Préréglages rapides
            Wrap(
              spacing: 8,
              children: [
                _buildPresetChip('50/50', () => _applyPreset5050(group)),
                _buildPresetChip('Proportionnel', () => _applyPresetProportional(group)),
                _buildPresetChip('Payeur exempté', () => _applyPresetPayerExempt(group)),
                _buildPresetChip('Personnalisé', () => _resetCustomAmounts(group)),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                final isIncluded = _splitOptions.includedMembers[member.id] ?? false;
                final isPayerHighlighted = member.id == _selectedPayerId;
                
                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: isPayerHighlighted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: isPayerHighlighted ? Text('Payeur', style: TextStyle(color: Colors.blue)) : null,
                      value: isIncluded,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            final updatedIncludedMembers = Map<String, bool>.from(_splitOptions.includedMembers);
                            updatedIncludedMembers[member.id] = value;
                            _splitOptions = _splitOptions.copyWith(includedMembers: updatedIncludedMembers);
                            
                            // Si on désélectionne un membre, mettre son montant à zéro
                            if (!value) {
                              final updatedCustomAmounts = Map<String, double>.from(_splitOptions.customAmounts);
                              updatedCustomAmounts[member.id] = 0.0;
                              _splitOptions = _splitOptions.copyWith(customAmounts: updatedCustomAmounts);
                            }
                          });
                        }
                      },
                      secondary: CircleAvatar(
                        child: Text(member.name[0].toUpperCase()),
                        backgroundColor: isPayerHighlighted ? Colors.blue : 
                                         (isIncluded ? Colors.green : Colors.grey),
                      ),
                    ),
                    if (isIncluded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            // Slider pour ajuster le montant visuellement
                            Row(
                              children: [
                                Icon(Icons.remove, size: 20),
                                Expanded(
                                  child: Slider(
                                    value: _splitOptions.customAmounts[member.id] ?? 0.0,
                                    min: 0,
                                    max: totalAmount,
                                    divisions: totalAmount > 100 ? 100 : totalAmount.toInt(),
                                    label: '${_splitOptions.customAmounts[member.id]?.toStringAsFixed(2) ?? '0.00'} $_selectedCurrency',
                                    onChanged: (value) {
                                      setState(() {
                                        final updatedCustomAmounts = Map<String, double>.from(_splitOptions.customAmounts);
                                        updatedCustomAmounts[member.id] = value;
                                        _splitOptions = _splitOptions.copyWith(customAmounts: updatedCustomAmounts);
                                      });
                                    },
                                  ),
                                ),
                                Icon(Icons.add, size: 20),
                              ],
                            ),
                            // Champ texte pour saisie précise
                            TextFormField(
                              initialValue: _splitOptions.customAmounts[member.id]?.toStringAsFixed(2) ?? '0.00',
                              decoration: InputDecoration(
                                labelText: 'Montant',
                                suffixText: _selectedCurrency,
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.euro),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setState(() {
                                  final updatedCustomAmounts = Map<String, double>.from(_splitOptions.customAmounts);
                                  updatedCustomAmounts[member.id] = double.tryParse(value) ?? 0.0;
                                  _splitOptions = _splitOptions.copyWith(customAmounts: updatedCustomAmounts);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.balance),
                    label: Text('Répartir le reste équitablement'),
                    onPressed: remaining > 0 ? () {
                      setState(() {
                        final includedMemberIds = _splitOptions.includedMembers.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();
                        
                        if (includedMemberIds.isNotEmpty) {
                          final perPersonRemaining = remaining / includedMemberIds.length;
                          final updatedCustomAmounts = Map<String, double>.from(_splitOptions.customAmounts);
                          
                          for (var memberId in includedMemberIds) {
                            updatedCustomAmounts[memberId] = (updatedCustomAmounts[memberId] ?? 0.0) + perPersonRemaining;
                          }
                          
                          _splitOptions = _splitOptions.copyWith(customAmounts: updatedCustomAmounts);
                        }
                      });
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour visualiser la répartition des dépenses
  Widget _buildDistributionVisualizer(TravelGroup group, double totalAmount) {
    if (totalAmount <= 0) return SizedBox(height: 0);
    
    final includedMembers = group.members.where(
      (member) => _splitOptions.includedMembers[member.id] ?? false
    ).toList();
    
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition actuelle:', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: includedMembers.map((member) {
                  final amount = _splitOptions.customAmounts[member.id] ?? 0.0;
                  final percentage = totalAmount > 0 ? (amount / totalAmount) : 0.0;
                  final isPayerHighlighted = member.id == _selectedPayerId;
                  
                  // Générer une couleur basée sur l'index du membre
                  final memberIndex = group.members.indexOf(member);
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                    Colors.indigo,
                  ];
                  final color = colors[memberIndex % colors.length];
                  
                  return Expanded(
                    flex: (percentage * 100).round(),
                    child: Container(
                      color: isPayerHighlighted ? color.shade700 : color,
                      child: percentage > 0.1 ? Center(
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget pour les préréglages rapides
  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(Icons.flash_on, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
  
  // Préréglage 50/50 (pour deux personnes)
  void _applyPreset5050(TravelGroup group) {
    if (group.members.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le préréglage 50/50 est conçu pour deux personnes'))
      );
      return;
    }
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;
    
    final halfAmount = totalAmount / 2;
    
    setState(() {
      // Inclure les deux membres
      final updatedIncludedMembers = <String, bool>{};
      final updatedCustomAmounts = <String, double>{};
      
      for (var member in group.members) {
        updatedIncludedMembers[member.id] = true;
        updatedCustomAmounts[member.id] = halfAmount;
      }
      
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        customAmounts: updatedCustomAmounts,
      );
    });
  }
  
  // Préréglage proportionnel (ex: selon le nombre de nuits)
  void _applyPresetProportional(TravelGroup group) {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;
    
    // Afficher une boîte de dialogue pour saisir les poids
    showDialog(
      context: context,
      builder: (context) {
        // Créer une map temporaire pour stocker les poids
        final tempWeights = <String, int>{};
        for (var member in group.members) {
          tempWeights[member.id] = _splitOptions.weights[member.id] ?? 1;
        }
        
        return AlertDialog(
          title: Text('Répartition proportionnelle'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Définissez le poids de chaque membre (ex: nombre de nuits, parts, etc.)'),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: group.members.length,
                    itemBuilder: (context, index) {
                      final member = group.members[index];
                      
                      return ListTile(
                        title: Text(member.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: tempWeights[member.id]! > 1 ? () {
                                setState(() {
                                  tempWeights[member.id] = tempWeights[member.id]! - 1;
                                });
                              } : null,
                            ),
                            Text('${tempWeights[member.id]}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  tempWeights[member.id] = tempWeights[member.id]! + 1;
                                });
                              },
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Calculer le total des poids
                final totalWeight = tempWeights.values.fold<int>(0, (sum, weight) => sum + weight);
                if (totalWeight == 0) {
                  Navigator.pop(context);
                  return;
                }
                
                // Calculer les montants proportionnels
                final updatedIncludedMembers = <String, bool>{};
                final updatedCustomAmounts = <String, double>{};
                final updatedWeights = <String, int>{};
                
                for (var member in group.members) {
                  final weight = tempWeights[member.id] ?? 0;
                  updatedIncludedMembers[member.id] = weight > 0;
                  updatedCustomAmounts[member.id] = totalAmount * (weight / totalWeight);
                  updatedWeights[member.id] = weight;
                }
                
                setState(() {
                  _splitOptions = _splitOptions.copyWith(
                    includedMembers: updatedIncludedMembers,
                    customAmounts: updatedCustomAmounts,
                    weights: updatedWeights,
                  );
                });
                
                Navigator.pop(context);
              },
              child: Text('Appliquer'),
            ),
          ],
        );
      },
    );
  }
  
  // Préréglage où le payeur est exempté
  void _applyPresetPayerExempt(TravelGroup group) {
    if (_selectedPayerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez d\'abord sélectionner un payeur'))
      );
      return;
    }
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;
    
    setState(() {
      // Inclure tous les membres sauf le payeur
      final updatedIncludedMembers = <String, bool>{};
      final updatedCustomAmounts = <String, double>{};
      
      final includedMembers = group.members
          .where((member) => member.id != _selectedPayerId)
          .toList();
      
      if (includedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Il n\'y a pas d\'autres membres à inclure'))
        );
        return;
      }
      
      final perPersonAmount = totalAmount / includedMembers.length;
      
      for (var member in group.members) {
        final isPayeur = member.id == _selectedPayerId;
        updatedIncludedMembers[member.id] = !isPayeur;
        updatedCustomAmounts[member.id] = isPayeur ? 0.0 : perPersonAmount;
      }
      
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        customAmounts: updatedCustomAmounts,
      );
    });
  }
  
  // Réinitialiser les montants personnalisés
  void _resetCustomAmounts(TravelGroup group) {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;
    
    setState(() {
      // Inclure tous les membres avec des montants à zéro
      final updatedIncludedMembers = <String, bool>{};
      final updatedCustomAmounts = <String, double>{};
      
      for (var member in group.members) {
        updatedIncludedMembers[member.id] = true;
        updatedCustomAmounts[member.id] = 0.0;
      }
      
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        customAmounts: updatedCustomAmounts,
      );
    });
  }

  // Construire la section de répartition par pourcentage
  Widget _buildPercentageSplitSection(TravelGroup group) {
    if (!_splitOptionsInitialized) return SizedBox();
    
    // Initialiser les pourcentages si nécessaire
    if (_splitOptions.percentages.isEmpty) {
      final equalPercentage = group.members.isNotEmpty ? 100.0 / group.members.length : 0.0;
      final updatedPercentages = <String, double>{};
      for (var member in group.members) {
        updatedPercentages[member.id] = equalPercentage;
      }
      _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
    }
    
    final totalPercentage = _splitOptions.percentages.entries
        .where((entry) => _splitOptions.includedMembers[entry.key] ?? false)
        .fold<double>(0.0, (sum, entry) => sum + entry.value);
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Visualisation en temps réel de la répartition
            _buildPercentageVisualizer(group),
            SizedBox(height: 16),
            // Indicateur de total des pourcentages
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (totalPercentage - 100.0).abs() < 0.1 ? 
                       Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    (totalPercentage - 100.0).abs() < 0.1 ? Icons.check_circle_outline : Icons.error_outline,
                    color: (totalPercentage - 100.0).abs() < 0.1 ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total des pourcentages: ${totalPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (totalPercentage - 100.0).abs() < 0.1 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Préréglages rapides pour les pourcentages
            Wrap(
              spacing: 8,
              children: [
                _buildPresetChip('Égal', () => _applyEqualPercentages(group)),
                _buildPresetChip('60/40', () => _applyPercentage6040(group)),
                _buildPresetChip('70/30', () => _applyPercentage7030(group)),
                _buildPresetChip('Personnalisé', () => _resetPercentages(group)),
              ],
            ),
            SizedBox(height: 16),
            Text('Qui participe à cette dépense ?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                final isIncluded = _splitOptions.includedMembers[member.id] ?? false;
                final percentage = _splitOptions.percentages[member.id] ?? 0.0;
                final memberAmount = amount * (percentage / 100.0);
                final isPayerHighlighted = member.id == _selectedPayerId;
                
                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: isPayerHighlighted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${memberAmount.toStringAsFixed(2)} $_selectedCurrency (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isIncluded,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            final updatedIncludedMembers = Map<String, bool>.from(_splitOptions.includedMembers);
                            updatedIncludedMembers[member.id] = value;
                            _splitOptions = _splitOptions.copyWith(includedMembers: updatedIncludedMembers);
                            
                            // Recalculer les pourcentages si nécessaire
                            if (value) {
                              _redistributePercentages();
                            } else {
                              // Si on désélectionne un membre, redistribuer son pourcentage
                              final currentPercentage = _splitOptions.percentages[member.id] ?? 0.0;
                              if (currentPercentage > 0) {
                                _redistributePercentageFromMember(member.id);
                              }
                            }
                          });
                        }
                      },
                      secondary: CircleAvatar(
                        child: Text(member.name[0].toUpperCase()),
                        backgroundColor: isPayerHighlighted ? Colors.blue : 
                                         (isIncluded ? Colors.green : Colors.grey),
                      ),
                    ),
                    if (isIncluded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            // Slider pour ajuster le pourcentage visuellement
                            Row(
                              children: [
                                Text('0%', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Slider(
                                    value: percentage,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: '${percentage.toStringAsFixed(1)}%',
                                    onChanged: (value) {
                                      setState(() {
                                        final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
                                        updatedPercentages[member.id] = value;
                                        _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
                                      });
                                    },
                                  ),
                                ),
                                Text('100%', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            // Champ texte pour saisie précise
                            TextFormField(
                              initialValue: percentage.toStringAsFixed(1),
                              decoration: InputDecoration(
                                labelText: 'Pourcentage',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                final newPercentage = double.tryParse(value) ?? 0.0;
                                setState(() {
                                  final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
                                  updatedPercentages[member.id] = newPercentage;
                                  _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.balance),
                    label: Text('Équilibrer à 100%'),
                    onPressed: (totalPercentage - 100.0).abs() > 0.1 ? () {
                      _balancePercentages();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour visualiser la répartition des pourcentages
  Widget _buildPercentageVisualizer(TravelGroup group) {
    final includedMembers = group.members.where(
      (member) => _splitOptions.includedMembers[member.id] ?? false
    ).toList();
    
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition actuelle:', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: includedMembers.map((member) {
                  final percentage = _splitOptions.percentages[member.id] ?? 0.0;
                  final isPayerHighlighted = member.id == _selectedPayerId;
                  
                  // Générer une couleur basée sur l'index du membre
                  final memberIndex = group.members.indexOf(member);
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                    Colors.indigo,
                  ];
                  final color = colors[memberIndex % colors.length];
                  
                  return Expanded(
                    flex: percentage > 0 ? percentage.round() : 1,
                    child: Container(
                      color: isPayerHighlighted ? color.shade700 : color,
                      child: percentage > 10 ? Center(
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Équilibrer les pourcentages pour atteindre 100%
  void _balancePercentages() {
    final includedMemberIds = _splitOptions.includedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (includedMemberIds.isEmpty) return;
    
    final totalPercentage = includedMemberIds
        .fold<double>(0.0, (sum, id) => sum + (_splitOptions.percentages[id] ?? 0.0));
    
    if (totalPercentage == 0) {
      // Si tous les pourcentages sont à zéro, répartir également
      _applyEqualPercentages(Provider.of<TravelGroupViewModel>(context, listen: false).currentGroup!);
      return;
    }
    
    // Ajuster proportionnellement pour atteindre 100%
    final scaleFactor = 100.0 / totalPercentage;
    final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
    
    for (var id in includedMemberIds) {
      updatedPercentages[id] = (updatedPercentages[id] ?? 0.0) * scaleFactor;
    }
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
    });
  }
  
  // Redistribuer les pourcentages quand on change les membres inclus
  void _redistributePercentages() {
    final includedMemberIds = _splitOptions.includedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (includedMemberIds.isEmpty) return;
    
    final equalPercentage = 100.0 / includedMemberIds.length;
    final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
    
    for (var id in includedMemberIds) {
      updatedPercentages[id] = equalPercentage;
    }
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
    });
  }
  
  // Redistribuer le pourcentage d'un membre exclu
  void _redistributePercentageFromMember(String excludedMemberId) {
    final currentPercentage = _splitOptions.percentages[excludedMemberId] ?? 0.0;
    if (currentPercentage <= 0) return;
    
    final includedMemberIds = _splitOptions.includedMembers.entries
        .where((entry) => entry.value && entry.key != excludedMemberId)
        .map((entry) => entry.key)
        .toList();
    
    if (includedMemberIds.isEmpty) return;
    
    final percentageToRedistribute = currentPercentage / includedMemberIds.length;
    final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
    
    updatedPercentages[excludedMemberId] = 0.0;
    for (var id in includedMemberIds) {
      updatedPercentages[id] = (updatedPercentages[id] ?? 0.0) + percentageToRedistribute;
    }
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
    });
  }
  
  // Appliquer une répartition égale des pourcentages
  void _applyEqualPercentages(TravelGroup group) {
    final includedMemberIds = _splitOptions.includedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (includedMemberIds.isEmpty) {
      // Si aucun membre n'est inclus, inclure tous les membres
      final updatedIncludedMembers = <String, bool>{};
      for (var member in group.members) {
        updatedIncludedMembers[member.id] = true;
      }
      _splitOptions = _splitOptions.copyWith(includedMembers: updatedIncludedMembers);
      includedMemberIds.addAll(group.members.map((m) => m.id));
    }
    
    final equalPercentage = 100.0 / includedMemberIds.length;
    final updatedPercentages = Map<String, double>.from(_splitOptions.percentages);
    
    for (var memberId in group.members.map((m) => m.id)) {
      updatedPercentages[memberId] = includedMemberIds.contains(memberId) ? equalPercentage : 0.0;
    }
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(percentages: updatedPercentages);
    });
  }
  
  // Appliquer une répartition 60/40
  void _applyPercentage6040(TravelGroup group) {
    if (group.members.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le préréglage 60/40 est conçu pour deux personnes'))
      );
      return;
    }
    
    final updatedIncludedMembers = <String, bool>{};
    final updatedPercentages = <String, double>{};
    
    updatedIncludedMembers[group.members[0].id] = true;
    updatedIncludedMembers[group.members[1].id] = true;
    
    updatedPercentages[group.members[0].id] = 60.0;
    updatedPercentages[group.members[1].id] = 40.0;
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        percentages: updatedPercentages,
      );
    });
  }
  
  // Appliquer une répartition 70/30
  void _applyPercentage7030(TravelGroup group) {
    if (group.members.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le préréglage 70/30 est conçu pour deux personnes'))
      );
      return;
    }
    
    final updatedIncludedMembers = <String, bool>{};
    final updatedPercentages = <String, double>{};
    
    updatedIncludedMembers[group.members[0].id] = true;
    updatedIncludedMembers[group.members[1].id] = true;
    
    updatedPercentages[group.members[0].id] = 70.0;
    updatedPercentages[group.members[1].id] = 30.0;
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        percentages: updatedPercentages,
      );
    });
  }
  
  // Réinitialiser les pourcentages
  void _resetPercentages(TravelGroup group) {
    final updatedIncludedMembers = <String, bool>{};
    final updatedPercentages = <String, double>{};
    
    for (var member in group.members) {
      updatedIncludedMembers[member.id] = true;
      updatedPercentages[member.id] = 0.0;
    }
    
    setState(() {
      _splitOptions = _splitOptions.copyWith(
        includedMembers: updatedIncludedMembers,
        percentages: updatedPercentages,
      );
    });
  }
}