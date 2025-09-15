import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../viewmodels/travel_group_viewmodel.dart';

class SharedExpenseFormScreen extends StatefulWidget {
  final String groupId;
  final SharedExpense? expense; // Null for a new expense
  final bool isDarkMode;
  final Function toggleTheme;

  const SharedExpenseFormScreen({
    super.key,
    required this.groupId,
    this.expense,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<SharedExpenseFormScreen> createState() =>
      _SharedExpenseFormScreenState();
}

class _SharedExpenseFormScreenState extends State<SharedExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _customAmountControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};

  String _selectedCategory = 'Food';
  String _selectedCurrency = 'EUR';
  DateTime _selectedDate = DateTime.now();
  String? _selectedPayerId;
  SplitType _splitType = SplitType.equal;

  @override
  void initState() {
    super.initState();
    _loadGroupData();

    if (widget.expense != null) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();

    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }

    for (var controller in _percentageControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _loadGroupData() {
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(
        context,
        listen: false,
      ).setCurrentGroup(widget.groupId);
    });
  }

  void _initializeControllers() {
    final expense = widget.expense!;

    _amountController.text = expense.amount.toString();
    _descriptionController.text = expense.description;
    _selectedCategory = expense.category;
    _selectedCurrency = expense.currency;
    _selectedDate = expense.date;
    _selectedPayerId = expense.payerId;
    _splitType = expense.splitType;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF4CD964),
              onPrimary: Colors.white,
              surface:
                  widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _initializeAmountControllers(List<GroupMember> members) {
    // Initialize controllers only once
    if (_customAmountControllers.isEmpty && widget.expense != null) {
      final expense = widget.expense!;

      for (var member in members) {
        // For custom amounts
        final amountController = TextEditingController();
        if (expense.splitAmounts.containsKey(member.id)) {
          amountController.text = expense.splitAmounts[member.id]!.toString();
        }
        _customAmountControllers[member.id] = amountController;

        // For percentages
        final percentageController = TextEditingController();
        if (expense.splitType == SplitType.percentage &&
            expense.splitAmounts.containsKey(member.id)) {
          final percentage =
              (expense.splitAmounts[member.id]! / expense.amount) * 100;
          percentageController.text = percentage.toStringAsFixed(1);
        } else {
          // Default to equal percentages
          percentageController.text = (100 / members.length).toStringAsFixed(1);
        }
        _percentageControllers[member.id] = percentageController;
      }
    } else if (_customAmountControllers.isEmpty) {
      // New expense - initialize empty controllers
      for (var member in members) {
        _customAmountControllers[member.id] = TextEditingController();
        _percentageControllers[member.id] = TextEditingController(
          text: (100 / members.length).toStringAsFixed(1),
        );
      }
    }
  }

  void _saveExpense(BuildContext context, TravelGroup group) {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<TravelGroupViewModel>(
        context,
        listen: false,
      );

      // Calculate split amounts
      Map<String, double> splitAmounts = {};

      switch (_splitType) {
        case SplitType.equal:
          final totalAmount = double.parse(_amountController.text);
          final perPersonAmount = totalAmount / group.members.length;

          for (var member in group.members) {
            splitAmounts[member.id] = perPersonAmount;
          }
          break;

        case SplitType.custom:
          for (var member in group.members) {
            final controller = _customAmountControllers[member.id];
            if (controller != null && controller.text.isNotEmpty) {
              splitAmounts[member.id] = double.parse(controller.text);
            } else {
              splitAmounts[member.id] = 0;
            }
          }
          break;

        case SplitType.percentage:
          final totalAmount = double.parse(_amountController.text);
          for (var member in group.members) {
            final controller = _percentageControllers[member.id];
            if (controller != null && controller.text.isNotEmpty) {
              final percentage = double.parse(controller.text);
              splitAmounts[member.id] = totalAmount * percentage / 100;
            } else {
              splitAmounts[member.id] = 0;
            }
          }
          break;

        case SplitType.weighted:
          // Handle weighted split similarly to percentage
          final totalAmount = double.parse(_amountController.text);
          final totalWeight = _percentageControllers.values
              .map((c) => double.tryParse(c.text) ?? 0.0)
              .fold<double>(0, (sum, weight) => sum + weight);

          if (totalWeight > 0) {
            for (var member in group.members) {
              final controller = _percentageControllers[member.id];
              if (controller != null && controller.text.isNotEmpty) {
                final weight = double.parse(controller.text);
                splitAmounts[member.id] = totalAmount * (weight / totalWeight);
              } else {
                splitAmounts[member.id] = 0;
              }
            }
          } else {
            // If no weights defined, fall back to equal split
            final perPersonAmount = totalAmount / group.members.length;
            for (var member in group.members) {
              splitAmounts[member.id] = perPersonAmount;
            }
          }
          break;
      }

      final expense = SharedExpense(
        id: widget.expense?.id,
        groupId: widget.groupId,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        currency: _selectedCurrency,
        payerId: _selectedPayerId!,
        splitType: _splitType,
        splitAmounts: splitAmounts,
      );

      if (widget.expense == null) {
        viewModel.addSharedExpense(expense);
      } else {
        viewModel.updateSharedExpense(expense);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.expense == null
                ? 'Expense added successfully' // Changed from "Dépense ajoutée avec succès"
                : 'Expense updated successfully', // Changed from "Dépense mise à jour avec succès"
          ),
          backgroundColor: const Color(0xFF4CD964),
        ),
      );
    }
  }

  void _distributeEqualPercentages(int memberCount) {
    double equalPercentage = 100 / memberCount;

    for (var controller in _percentageControllers.values) {
      controller.text = equalPercentage.toStringAsFixed(1);
    }
  }

  void _distributeEqualAmounts(double totalAmount, int memberCount) {
    double equalAmount = totalAmount / memberCount;

    for (var controller in _customAmountControllers.values) {
      controller.text = equalAmount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelGroupViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(
            backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
            appBar: AppBar(
              title: Text(
                widget.expense == null
                    ? 'Add Expense'
                    : 'Edit Expense', // Changed from French
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CD964)),
            ),
          );
        }

        final group = viewModel.currentGroup;
        if (group == null) {
          return Scaffold(
            backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
            appBar: AppBar(
              title: Text(
                'Error', // Changed from French
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            body: Center(
              child: Text('Group not found'),
            ), // Changed from "Groupe non trouvé"
          );
        }

        // Initialize controllers for members
        _initializeAmountControllers(group.members);

        // If no payer selected, default to first member
        if (_selectedPayerId == null && group.members.isNotEmpty) {
          _selectedPayerId = group.members[0].id;
        }

        return Scaffold(
          backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor:
                widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            title: Text(
              widget.expense == null
                  ? 'Add Expense'
                  : 'Edit Expense', // Changed from French
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [], // Remove theme toggle button
          ),
          body: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main expense details card - Pass group parameter here
                      _buildExpenseDetailsCard(context, group),

                      // Split method section
                      _buildSplitMethodSection(group),

                      // Spacer to push the save button to the bottom
                      const Spacer(),

                      // Save button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => _saveExpense(context, group),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CD964),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.expense == null
                                ? 'Add Expense'
                                : 'Update Expense',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New clean expense details card with better layout
  Widget _buildExpenseDetailsCard(BuildContext context, TravelGroup group) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title label
            Text(
              'EXPENSE DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF4CD964).withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CD964),
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF4CD964),
                ),
              ),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount and currency row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF4CD964).withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CD964),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Color(0xFF4CD964),
                      ),
                    ),
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF4CD964).withOpacity(0.5),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items:
                        ['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF']
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              ),
                            )
                            .toList(),
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    dropdownColor:
                        widget.isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category and Date row
            Row(
              children: [
                // Category dropdown - more aggressive fixes
                // Adjust category dropdown content padding for better text positioning
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF4CD964).withOpacity(0.5),
                        ),
                      ),
                      // Adjust padding to give more space on the left for better text alignment
                      contentPadding: const EdgeInsets.fromLTRB(12, 14, 6, 14),
                      // Still no prefix icon to save space
                    ),
                    isDense: true,
                    alignment:
                        AlignmentDirectional.center, // Center the dropdown text
                    // Rest of the properties remain the same
                    items:
                        [
                              'Food',
                              'Accommodation',
                              'Transportation',
                              'Activities',
                              'Shopping',
                              'Other',
                            ]
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    dropdownColor:
                        widget.isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Date picker with button
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF4CD964).withOpacity(0.5),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4CD964),
                        ),
                      ),
                      child: Text(
                        DateFormat('MM/dd/yyyy').format(_selectedDate),
                        style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payer selector with improved UI
            Text(
              'PAID BY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4CD964).withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPayerId,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF4CD964),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor:
                      widget.isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                  // Now we have access to the group parameter
                  items:
                      group.members
                          .map(
                            (member) => DropdownMenuItem<String>(
                              value: member.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF4CD964),
                                    radius: 16,
                                    child: Text(
                                      member.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(member.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPayerId = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Improved split method section with better visual cues
  Widget _buildSplitMethodSection(TravelGroup group) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color:
                      widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'SPLIT METHOD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Improved split type selector with icons - Fix here
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<SplitType>(
                thumbColor: const Color(0xFF4CD964),
                backgroundColor:
                    widget.isDarkMode ? Colors.black26 : Colors.grey.shade200,
                padding: const EdgeInsets.all(4),
                groupValue: _splitType,
                children: {
                  SplitType.equal: _buildSegmentedControlItem(
                    icon: Icons.balance,
                    label: 'Equal',
                    isSelected: _splitType == SplitType.equal,
                  ),
                  SplitType.custom: _buildSegmentedControlItem(
                    icon: Icons.edit,
                    label: 'Custom',
                    isSelected: _splitType == SplitType.custom,
                  ),
                  SplitType.percentage: _buildSegmentedControlItem(
                    icon: Icons.percent,
                    label: 'Percent',
                    isSelected: _splitType == SplitType.percentage,
                  ),
                  SplitType.weighted: _buildSegmentedControlItem(
                    icon: Icons.line_weight,
                    label: 'Weighted',
                    isSelected: _splitType == SplitType.weighted,
                  ),
                },
                onValueChanged: (SplitType? value) {
                  if (value != null) {
                    setState(() {
                      _splitType = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Split details based on selected method
            _buildSplitDetails(group),
          ],
        ),
      ),
    );
  }

  // Helper method for segmented control items
  Widget _buildSegmentedControlItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    // Make "Weighted" text smaller or use "Weight" instead
    final displayLabel = label == 'Weighted' ? 'Weight' : label;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 8,
      ), // Reduce horizontal padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14, // Make icon slightly smaller
            color:
                isSelected
                    ? Colors.black
                    : (widget.isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 2), // Reduce spacing
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 11, // Make font smaller
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected
                      ? Colors.black
                      : (widget.isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Build split details based on selected split type
  Widget _buildSplitDetails(TravelGroup group) {
    switch (_splitType) {
      case SplitType.equal:
        return _buildEqualSplit(group);
      case SplitType.custom:
        return _buildCustomSplit(group);
      case SplitType.percentage:
        return _buildPercentageSplit(group);
      case SplitType.weighted:
        // Use the same UI as percentage, just change the label text
        return _buildWeightedSplit(group);
    }
  }

  // Improved equal split section with visualization
  Widget _buildEqualSplit(TravelGroup group) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final perPersonAmount =
        group.members.isNotEmpty ? amount / group.members.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visualization banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CD964).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD964).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Color(0xFF4CD964)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equal Split',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Each person pays ${perPersonAmount.toStringAsFixed(2)} $_selectedCurrency',
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members visualization with avatar chips
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children:
              group.members.map((member) {
                final isSelected = true; // In equal split, everyone is included
                final isPayer = member.id == _selectedPayerId;

                return _buildMemberChip(
                  member: member,
                  isSelected: isSelected,
                  isPayer: isPayer,
                  amount: perPersonAmount,
                  onToggle: null, // Cannot toggle in equal split
                );
              }).toList(),
        ),
      ],
    );
  }

  // Custom split section with better visualization
  Widget _buildCustomSplit(TravelGroup group) {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    double currentTotal = 0.0;

    // Calculate current total
    for (var member in group.members) {
      final controllerText = _customAmountControllers[member.id]?.text ?? '';
      if (controllerText.isNotEmpty) {
        currentTotal += double.tryParse(controllerText) ?? 0.0;
      }
    }

    final remaining = totalAmount - currentTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                remaining.abs() < 0.01
                    ? const Color(0xFF4CD964).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      remaining.abs() < 0.01
                          ? const Color(0xFF4CD964).withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  remaining.abs() < 0.01 ? Icons.check_circle : Icons.warning,
                  color:
                      remaining.abs() < 0.01
                          ? const Color(0xFF4CD964)
                          : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining.abs() < 0.01 ? 'All set!' : 'Not balanced',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      remaining.abs() < 0.01
                          ? 'Custom amounts add up correctly'
                          : 'Remaining: ${remaining.toStringAsFixed(2)} $_selectedCurrency',
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              icon: Icons.balance,
              label: 'Split equally',
              onTap: () {
                if (totalAmount > 0 && group.members.isNotEmpty) {
                  _distributeEqualAmounts(totalAmount, group.members.length);
                }
              },
            ),
            _buildActionChip(
              icon: Icons.person_off,
              label: 'Payer exempt',
              onTap: () {
                if (totalAmount > 0 &&
                    group.members.length > 1 &&
                    _selectedPayerId != null) {
                  _excludePayerFromSplit(group);
                }
              },
            ),
            _buildActionChip(
              icon: Icons.refresh,
              label: 'Reset',
              onTap: () {
                _resetCustomAmounts();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Member amount inputs with better layout
        Column(
          children:
              group.members.map((member) {
                final controller = _customAmountControllers[member.id];
                final isPayer = member.id == _selectedPayerId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Member avatar
                      CircleAvatar(
                        backgroundColor:
                            isPayer
                                ? const Color(0xFF4CD964)
                                : Colors.grey.shade300,
                        radius: 20,
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color:
                                isPayer ? Colors.black : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Member info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: TextStyle(
                                fontWeight:
                                    isPayer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            if (isPayer)
                              const Text(
                                'Payer',
                                style: TextStyle(
                                  color: Color(0xFF4CD964),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Amount input with currency
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            suffixText: _selectedCurrency,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {}); // Refresh UI to update total
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),

        // Auto-balance button
        if (remaining.abs() > 0.01)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _autoBalanceRemainingAmount(group),
              icon: const Icon(Icons.balance),
              label: const Text('Balance Remaining'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  // Helper to create a stylish action chip
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF4CD964)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF252525) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF4CD964).withOpacity(0.3)),
      ),
      onPressed: onTap,
    );
  }

  // Helper to create a member chip
  Widget _buildMemberChip({
    required GroupMember member,
    required bool isSelected,
    required bool isPayer,
    required double amount,
    required Function? onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle == null ? null : () => onToggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isPayer
                      ? const Color(0xFF4CD964).withOpacity(0.2)
                      : Colors.grey.shade200)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? (isPayer ? const Color(0xFF4CD964) : Colors.grey)
                    : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor:
                  isPayer ? const Color(0xFF4CD964) : Colors.grey.shade400,
              radius: 16,
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: isPayer ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPayer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} $_selectedCurrency',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (isPayer)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.credit_card,
                  size: 14,
                  color: Color(0xFF4CD964),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New helper method to exclude payer from split
  void _excludePayerFromSplit(TravelGroup group) {
    if (_selectedPayerId == null) return;

    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;

    final nonPayerMembers =
        group.members.where((member) => member.id != _selectedPayerId).toList();

    if (nonPayerMembers.isEmpty) return;

    final perPersonAmount = totalAmount / nonPayerMembers.length;

    setState(() {
      for (var member in group.members) {
        final controller = _customAmountControllers[member.id];
        if (controller != null) {
          controller.text =
              member.id == _selectedPayerId
                  ? '0.00'
                  : perPersonAmount.toStringAsFixed(2);
        }
      }
    });
  }

  // New improved method to auto-balance remaining amount
  void _autoBalanceRemainingAmount(TravelGroup group) {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return;

    double currentTotal = 0.0;
    for (var member in group.members) {
      final controllerText = _customAmountControllers[member.id]?.text ?? '';
      if (controllerText.isNotEmpty) {
        currentTotal += double.tryParse(controllerText) ?? 0.0;
      }
    }

    final remaining = totalAmount - currentTotal;
    if (remaining.abs() < 0.01) return;

    // Strategy: first distribute to members with zero amount, if none, distribute equally
    List<GroupMember> zeroAmountMembers = [];
    for (var member in group.members) {
      final controller = _customAmountControllers[member.id];
      if (controller != null) {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount <= 0) {
          zeroAmountMembers.add(member);
        }
      }
    }

    setState(() {
      if (zeroAmountMembers.isNotEmpty) {
        // Distribute to zero amount members
        final perPersonAmount = remaining / zeroAmountMembers.length;
        for (var member in zeroAmountMembers) {
          final controller = _customAmountControllers[member.id];
          if (controller != null) {
            controller.text = perPersonAmount.toStringAsFixed(2);
          }
        }
      } else {
        // Distribute equally among all
        final perPersonAmount = remaining / group.members.length;
        for (var member in group.members) {
          final controller = _customAmountControllers[member.id];
          if (controller != null) {
            final currentAmount = double.tryParse(controller.text) ?? 0.0;
            controller.text = (currentAmount + perPersonAmount).toStringAsFixed(
              2,
            );
          }
        }
      }
    });
  }

  // Reset all custom amounts to zero
  void _resetCustomAmounts() {
    setState(() {
      for (var controller in _customAmountControllers.values) {
        controller.text = '0.00';
      }
    });
  }

  // Percentage split section
  Widget _buildPercentageSplit(TravelGroup group) {
    double totalPercentage = 0.0;

    // Calculate current total percentage
    for (var member in group.members) {
      final controllerText = _percentageControllers[member.id]?.text ?? '';
      if (controllerText.isNotEmpty) {
        totalPercentage += double.tryParse(controllerText) ?? 0.0;
      }
    }

    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color:
                  (totalPercentage - 100.0).abs() < 0.1
                      ? const Color(0xFF4CD964).withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          color:
              widget.isDarkMode
                  ? const Color(0xFF2E2E2E)
                  : (totalPercentage - 100.0).abs() < 0.1
                  ? const Color(0xFF4CD964).withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  (totalPercentage - 100.0).abs() < 0.1
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color:
                      (totalPercentage - 100.0).abs() < 0.1
                          ? const Color(0xFF4CD964)
                          : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total percentage: ${totalPercentage.toStringAsFixed(1)}%', // Changed from French
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (totalPercentage - 100.0).abs() < 0.1
                                  ? const Color(0xFF4CD964)
                                  : Colors.orange,
                        ),
                      ),
                      if ((totalPercentage - 100.0).abs() >= 0.1)
                        const Text(
                          'The total should be 100%', // Changed from French
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.balance, size: 18),
              label: const Text('Equal percentages'), // Changed from French
              onPressed: () {
                setState(() {
                  _distributeEqualPercentages(group.members.length);
                });
              },
            ),
            if (group.members.length == 2)
              ActionChip(
                avatar: const Icon(Icons.pie_chart, size: 18),
                label: const Text('60/40 split'), // Changed from French
                onPressed: () {
                  setState(() {
                    _percentageControllers[group.members[0].id]?.text = '60.0';
                    _percentageControllers[group.members[1].id]?.text = '40.0';
                  });
                },
              ),
            if (group.members.length == 2)
              ActionChip(
                avatar: const Icon(Icons.pie_chart, size: 18),
                label: const Text('70/30 split'), // Changed from French
                onPressed: () {
                  setState(() {
                    _percentageControllers[group.members[0].id]?.text = '70.0';
                    _percentageControllers[group.members[1].id]?.text = '30.0';
                  });
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'), // Changed from French
              onPressed: () {
                setState(() {
                  for (var controller in _percentageControllers.values) {
                    controller.text = '0.0';
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Percentage input for each member
        Column(
          children:
              group.members.map((member) {
                final percentageController = _percentageControllers[member.id];
                final percentage =
                    double.tryParse(percentageController?.text ?? '0.0') ?? 0.0;
                final memberAmount = totalAmount * (percentage / 100.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            member.id == _selectedPayerId
                                ? const Color(0xFF4CD964)
                                : Colors.grey,
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
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
                                fontWeight:
                                    member.id == _selectedPayerId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${memberAmount.toStringAsFixed(2)} $_selectedCurrency',
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            if (member.id == _selectedPayerId)
                              const Text(
                                'Payer', // Changed from "Payeur"
                                style: TextStyle(
                                  color: Color(0xFF4CD964),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: percentageController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                'Percentage', // Changed from "Pourcentage"
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {}); // Refresh UI to update total
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),

        // Balance percentages button
        if ((totalPercentage - 100.0).abs() >= 0.1)
          ElevatedButton.icon(
            onPressed: () {
              if (totalPercentage == 0) {
                // If all percentages are zero, distribute equally
                _distributeEqualPercentages(group.members.length);
              } else {
                // Scale all percentages to sum to 100%
                final scaleFactor = 100.0 / totalPercentage;

                setState(() {
                  for (var member in group.members) {
                    final controller = _percentageControllers[member.id];
                    if (controller != null) {
                      final currentPercentage =
                          double.tryParse(controller.text) ?? 0.0;
                      controller.text = (currentPercentage * scaleFactor)
                          .toStringAsFixed(1);
                    }
                  }
                });
              }
            },
            icon: const Icon(Icons.balance),
            label: const Text('Balance to 100%'), // Changed from French
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }

  // Add new method for weighted split UI
  Widget _buildWeightedSplit(TravelGroup group) {
    // We can reuse most of the percentage split UI but change labels
    // This is similar to _buildPercentageSplit but with "weight" terminology
    // instead of "percentage"

    double totalWeight = 0.0;

    // Calculate current total weight
    for (var member in group.members) {
      final controllerText = _percentageControllers[member.id]?.text ?? '';
      if (controllerText.isNotEmpty) {
        totalWeight += double.tryParse(controllerText) ?? 0.0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color:
                  totalWeight > 0
                      ? const Color(0xFF4CD964).withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          color:
              widget.isDarkMode
                  ? const Color(0xFF2E2E2E)
                  : totalWeight > 0
                  ? const Color(0xFF4CD964).withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  totalWeight > 0
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color:
                      totalWeight > 0 ? const Color(0xFF4CD964) : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total weight: ${totalWeight.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              totalWeight > 0
                                  ? const Color(0xFF4CD964)
                                  : Colors.orange,
                        ),
                      ),
                      if (totalWeight <= 0)
                        const Text(
                          'Add weights to split the expense',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.balance, size: 18),
              label: const Text('Equal weights'),
              onPressed: () {
                setState(() {
                  _distributeEqualPercentages(group.members.length);
                });
              },
            ),
            if (group.members.length == 2)
              ActionChip(
                avatar: const Icon(Icons.pie_chart, size: 18),
                label: const Text('2:1 ratio'),
                onPressed: () {
                  setState(() {
                    _percentageControllers[group.members[0].id]?.text = '2.0';
                    _percentageControllers[group.members[1].id]?.text = '1.0';
                  });
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              onPressed: () {
                setState(() {
                  for (var controller in _percentageControllers.values) {
                    controller.text = '0.0';
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rest is similar to percentage UI with different labels
        // ...existing percentage layout with "Weight" instead of "Percentage" labels...
        Column(
          children:
              group.members.map((member) {
                final weightController = _percentageControllers[member.id];
                final weight =
                    double.tryParse(weightController?.text ?? '0.0') ?? 0.0;
                final totalWeight = _percentageControllers.values
                    .map((c) => double.tryParse(c.text) ?? 0.0)
                    .fold<double>(0, (sum, w) => sum + w);

                // Fix the null check issue here by safely handling the null case
                final totalAmount =
                    double.tryParse(_amountController.text) ?? 0.0;
                final memberAmount =
                    totalWeight > 0
                        ? totalAmount * (weight / totalWeight)
                        : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    // Similar to percentage row but with "Weight" instead of "Percentage"
                    // ...copy the same row structure but adapt labels...
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            member.id == _selectedPayerId
                                ? const Color(0xFF4CD964)
                                : Colors.grey,
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
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
                                fontWeight:
                                    member.id == _selectedPayerId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${memberAmount.toStringAsFixed(2)} $_selectedCurrency',
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            if (member.id == _selectedPayerId)
                              const Text(
                                'Payer',
                                style: TextStyle(
                                  color: Color(0xFF4CD964),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Weight',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {}); // Refresh UI to update total
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
