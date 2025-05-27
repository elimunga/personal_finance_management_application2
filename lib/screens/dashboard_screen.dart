import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'savings_screen.dart';
import 'transaction_screen.dart';
import 'budget_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, dynamic> _quickStats = {
    'totalIncome': 0.0,
    'totalExpenses': 0.0,
    'balance': 0.0,
    'currency': 'USD', // Default currency
  };

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'KES': 'KSh',
  };

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      // Listen to user data changes
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _userData = snapshot.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'User profile not found';
            _isLoading = false;
          });
        }
      });

      // Listen to transactions changes
      _transactionsSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _recentTransactions = snapshot.docs
                .take(5)
                .map((doc) => doc.data())
                .toList();

            // Calculate quick stats
            double totalIncome = 0;
            double totalExpenses = 0;
            String currency = 'USD'; // Default currency

            for (var transaction in snapshot.docs) {
              final data = transaction.data();
              final amount = (data['amount'] as num).toDouble();
              currency = data['currency'] as String? ?? 'USD';
              if (data['type'] == 'income') {
                totalIncome += amount;
              } else {
                totalExpenses += amount;
              }
            }

            _quickStats = {
              'totalIncome': totalIncome,
              'totalExpenses': totalExpenses,
              'balance': totalIncome - totalExpenses,
              'currency': currency,
            };
          });
        } else {
          setState(() {
            _recentTransactions = [];
            _quickStats = {
              'totalIncome': 0.0,
              'totalExpenses': 0.0,
              'balance': 0.0,
              'currency': 'USD',
            };
          });
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_userData?['firstName'] ?? 'User'}'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}',
              ),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${_userData?['firstName']?[0] ?? ''}${_userData?['lastName']?[0] ?? ''}',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Savings Goals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Income',
                          _quickStats['totalIncome'],
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Expenses',
                          _quickStats['totalExpenses'],
                          Colors.red,
                        ),
                        _buildStatItem(
                          'Balance',
                          _quickStats['balance'],
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Recent Transactions
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_recentTransactions.isEmpty)
              const Center(
                child: Text(
                  'No recent transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _recentTransactions[index];
                  final amount = (transaction['amount'] as num).toDouble();
                  final type = transaction['type'] as String;
                  final category = transaction['category'] as String;
                  final description = transaction['description'] as String;
                  final date = (transaction['date'] as Timestamp).toDate();
                  final currency = transaction['currency'] as String? ?? 'USD';
                  final currencySymbol = _currencySymbols[currency] ?? '\$';

                  return ListTile(
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
                      '$currencySymbol${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: type == 'income' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context,
                  'Add Transaction',
                  Icons.add_circle,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Set Budget',
                  Icons.account_balance_wallet,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Savings',
                  Icons.savings,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingsScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Notifications',
                  Icons.notifications,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    final currencySymbol = _currencySymbols[_quickStats['currency']] ?? '\$';
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currencySymbol${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 