import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeDatabase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Initialize user profile
      await _initializeUserProfile(user.uid);

      // Initialize transactions
      await _initializeTransactions(user.uid);

      // Initialize budgets
      await _initializeBudgets(user.uid);

      // Initialize savings goals
      await _initializeSavingsGoals(user.uid);

      print('Database initialized successfully!');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _initializeUserProfile(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userId).set({
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _initializeTransactions(String userId) async {
    final transactionsRef = _firestore.collection('transactions');
    
    // Sample transactions
    final transactions = [
      {
        'userId': userId,
        'amount': 1200.00,
        'type': 'income',
        'description': 'Salary',
        'category': 'Work',
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'userId': userId,
        'amount': 50.00,
        'type': 'expense',
        'description': 'Grocery Shopping',
        'category': 'Food',
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'userId': userId,
        'amount': 30.00,
        'type': 'expense',
        'description': 'Movie Tickets',
        'category': 'Entertainment',
        'timestamp': FieldValue.serverTimestamp(),
      },
    ];

    for (var transaction in transactions) {
      await transactionsRef.add(transaction);
    }
  }

  Future<void> _initializeBudgets(String userId) async {
    final budgetsRef = _firestore.collection('budgets');
    
    // Sample budgets
    final budgets = [
      {
        'userId': userId,
        'category': 'Food',
        'total': 500.00,
        'spent': 250.00,
        'period': 'monthly',
      },
      {
        'userId': userId,
        'category': 'Entertainment',
        'total': 200.00,
        'spent': 75.00,
        'period': 'monthly',
      },
      {
        'userId': userId,
        'category': 'Transportation',
        'total': 300.00,
        'spent': 150.00,
        'period': 'monthly',
      },
    ];

    for (var budget in budgets) {
      await budgetsRef.add(budget);
    }
  }

  Future<void> _initializeSavingsGoals(String userId) async {
    final savingsRef = _firestore.collection('savings');
    
    // Sample savings goals
    final savingsGoals = [
      {
        'userId': userId,
        'goal': 'Vacation Fund',
        'targetAmount': 2000.00,
        'currentAmount': 500.00,
        'targetDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 180)),
        ),
      },
      {
        'userId': userId,
        'goal': 'Emergency Fund',
        'targetAmount': 5000.00,
        'currentAmount': 2000.00,
        'targetDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
      },
    ];

    for (var goal in savingsGoals) {
      await savingsRef.add(goal);
    }
  }
} 