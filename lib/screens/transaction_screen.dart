import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _selectedCurrency = 'USD';
  String _currencySymbol = '\$';

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Fees',
    'Water Bill',
    'Electricity Bill',
    'Entertainment',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gifts',
    'Refund',
    'Other',
  ];

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'KES': 'KSh',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'USD';
      _currencySymbol = _currencySymbols[_selectedCurrency] ?? '\$';
    });
  }

  String _formatAmount(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc(transactionId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: '$_currencySymbol ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Expense'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Income'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                          // Reset category to first item of the new type
                          _selectedCategory = value == 'expense'
                              ? _expenseCategories[0]
                              : _incomeCategories[0];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: (_selectedType == 'expense'
                            ? _expenseCategories
                            : _incomeCategories)
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Add Transaction Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addTransaction,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Transaction'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recent Transactions List
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return const Text('No transactions yet');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final type = data['type'] as String? ?? 'expense';
                    final category = data['category'] as String? ?? 'Other';
                    final description = data['description'] as String? ?? '';
                    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                'Are you sure you want to delete this transaction?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deleteTransaction(doc.id);
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                type == 'income' ? Colors.green : Colors.red,
                            child: Icon(
                              type == 'income' ? Icons.add : Icons.remove,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(description),
                          subtitle: Text(
                            '${category} • ${DateFormat('MMM dd, yyyy').format(date)}',
                          ),
                          trailing: Text(
                            _formatAmount(amount),
                            style: TextStyle(
                              color: type == 'income' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final amount = double.parse(_amountController.text);
          final category = _selectedCategory;
          final type = _selectedType;

          // Only check budget for expenses
          if (type == 'expense') {
            try {
              // Get the budget for this category
              final budgetDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('budgets')
                  .where('category', isEqualTo: category)
                  .get();

              if (budgetDoc.docs.isNotEmpty) {
                final budgetData = budgetDoc.docs.first.data();
                final budgetAmount = (budgetData['amount'] as num?)?.toDouble() ?? 0.0;

                // Get total expenses for this category in the current month
                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);
                final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

                // Get all expenses for the category
                final expensesSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('transactions')
                    .where('category', isEqualTo: category)
                    .where('type', isEqualTo: 'expense')
                    .get();

                double totalExpenses = 0;
                for (var doc in expensesSnapshot.docs) {
                  final data = doc.data();
                  final transactionDate = (data['date'] as Timestamp?)?.toDate();
                  if (transactionDate != null &&
                      transactionDate.isAfter(firstDayOfMonth) &&
                      transactionDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
                    totalExpenses += (data['amount'] as num?)?.toDouble() ?? 0.0;
                  }
                }

                // Add the new transaction amount
                totalExpenses += amount;

                // Calculate percentage of budget used
                final percentage = budgetAmount > 0 ? totalExpenses / budgetAmount : 0.0;

                // Check if budget is exceeded or reaching thresholds
                if (percentage >= 1.0) {
                  // Create notification for budget exceeded
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .add({
                    'type': 'budget_exceeded',
                    'message': 'Budget exceeded for $category category. Current spending: ${_formatAmount(totalExpenses)} of ${_formatAmount(budgetAmount)}',
                    'category': category,
                    'currentAmount': totalExpenses,
                    'budgetAmount': budgetAmount,
                    'createdAt': FieldValue.serverTimestamp(),
                    'read': false,
                  });

                  // Show immediate notification to user
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Budget exceeded for $category!'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else if (percentage >= 0.75) {
                  // Create warning notification when reaching 75% of budget
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .add({
                    'type': 'budget_warning_75',
                    'message': 'You\'ve used 75% of your $category budget. Current spending: ${_formatAmount(totalExpenses)} of ${_formatAmount(budgetAmount)}',
                    'category': category,
                    'currentAmount': totalExpenses,
                    'budgetAmount': budgetAmount,
                    'createdAt': FieldValue.serverTimestamp(),
                    'read': false,
                  });

                  // Show immediate notification to user
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Warning: 75% of $category budget used!'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else if (percentage >= 0.5) {
                  // Create warning notification when reaching 50% of budget
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .add({
                    'type': 'budget_warning_50',
                    'message': 'You\'ve used 50% of your $category budget. Current spending: ${_formatAmount(totalExpenses)} of ${_formatAmount(budgetAmount)}',
                    'category': category,
                    'currentAmount': totalExpenses,
                    'budgetAmount': budgetAmount,
                    'createdAt': FieldValue.serverTimestamp(),
                    'read': false,
                  });

                  // Show immediate notification to user
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notice: 50% of $category budget used'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              print('Error checking budget: $e');
            }
          }

          // Create transaction data
          final transactionData = {
            'amount': amount,
            'type': type,
            'category': category,
            'description': _descriptionController.text,
            'date': Timestamp.fromDate(_selectedDate),
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Add transaction to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .add(transactionData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction added successfully')),
            );
            _formKey.currentState!.reset();
            _amountController.clear();
            _descriptionController.clear();
            setState(() {
              _selectedDate = DateTime.now();
              _selectedType = 'expense';
              _selectedCategory = _expenseCategories[0];
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding transaction: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 