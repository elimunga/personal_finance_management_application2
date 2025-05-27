import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isLoading = false;
  String _selectedCurrency = 'USD';
  String _currencySymbol = '\$';

  final List<String> _categories = [
    'Food',
    'Transport',
    'Fees',
    'Water Bill',
    'Electricity Bill',
    'Entertainment',
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

  Future<void> _deleteBudget(String budgetId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('budgets')
            .doc(budgetId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget: $e')),
        );
      }
    }
  }

  Future<double> _getCategorySpending(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    try {
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

      double totalSpent = 0;
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final transactionDate = (data['date'] as Timestamp?)?.toDate();
        if (transactionDate != null &&
            transactionDate.isAfter(firstDayOfMonth) &&
            transactionDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
          totalSpent += (data['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return totalSpent;
    } catch (e) {
      print('Error calculating spending for category $category: $e');
      return 0.0;
    }
  }

  Future<void> _checkAndCreateNotification(
    String category,
    double spent,
    double budget,
    double percentage,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String message;
      String type;

      if (percentage >= 1.0) {
        message = 'Budget exceeded for $category category. Current spending: ${_formatAmount(spent)} of ${_formatAmount(budget)}';
        type = 'budget_exceeded';
      } else if (percentage >= 0.75) {
        message = 'You\'ve used 75% of your $category budget. Current spending: ${_formatAmount(spent)} of ${_formatAmount(budget)}';
        type = 'budget_warning_75';
      } else if (percentage >= 0.5) {
        message = 'You\'ve used 50% of your $category budget. Current spending: ${_formatAmount(spent)} of ${_formatAmount(budget)}';
        type = 'budget_warning_50';
      } else {
        return;
      }

      // Check if a notification for this threshold already exists in the last 24 hours
      final existingNotification = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: type)
          .where('category', isEqualTo: category)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 24)),
          ))
          .get();

      if (existingNotification.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'type': type,
          'message': message,
          'category': category,
          'currentAmount': spent,
          'budgetAmount': budget,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });

        // Show immediate notification to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: percentage >= 1.0 ? Colors.red : 
                             percentage >= 0.75 ? Colors.orange : Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating notification for category $category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories
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
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Budget Amount',
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
                  const SizedBox(height: 24),
                  // Add Budget Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addBudget,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Set Budget'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Current Budgets List
            const Text(
              'Current Budgets',
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
                  .collection('budgets')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return const Text('No budgets set yet');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final category = data['category'] as String? ?? 'Other';

                    return FutureBuilder<double>(
                      future: _getCategorySpending(category),
                      builder: (context, spendingSnapshot) {
                        final spent = spendingSnapshot.data ?? 0.0;
                        final remaining = amount - spent;
                        final percentage = amount > 0 ? spent / amount : 0.0;

                        // Check for notifications
                        if (spendingSnapshot.hasData) {
                          _checkAndCreateNotification(
                            category,
                            spent,
                            amount,
                            percentage,
                          );
                        }

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
                                    'Are you sure you want to delete this budget?',
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
                            _deleteBudget(doc.id);
                          },
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: percentage.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentage >= 1.0 ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Spent: ${_formatAmount(spent)}',
                                        style: TextStyle(
                                          color: percentage >= 1.0 ? Colors.red : Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        'Remaining: ${_formatAmount(remaining)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Budget: ${_formatAmount(amount)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Future<void> _addBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final amount = double.parse(_amountController.text);
          final category = _selectedCategory;

          // Check if budget already exists for this category
          final existingBudget = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('budgets')
              .where('category', isEqualTo: category)
              .get();

          if (existingBudget.docs.isNotEmpty) {
            // Update existing budget
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('budgets')
                .doc(existingBudget.docs.first.id)
                .update({
              'amount': amount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Create new budget
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('budgets')
                .add({
              'category': category,
              'amount': amount,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          // Check current spending and create notification if needed
          final currentSpending = await _getCategorySpending(category);
          final percentage = amount > 0 ? currentSpending / amount : 0.0;
          await _checkAndCreateNotification(category, currentSpending, amount, percentage);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Budget set successfully')),
            );
            _formKey.currentState!.reset();
            _amountController.clear();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error setting budget: $e')),
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
    super.dispose();
  }
} 