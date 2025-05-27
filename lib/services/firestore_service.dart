import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Profile Operations
  Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).set(userData);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).update(userData);
  }

  // Transaction Operations
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    transactionData['userId'] = userId;
    transactionData['timestamp'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('transactions').add(transactionData);
  }

  Stream<QuerySnapshot> getTransactions() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Budget Operations
  Future<void> addBudget(Map<String, dynamic> budgetData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    budgetData['userId'] = userId;
    await _firestore.collection('budgets').add(budgetData);
  }

  Stream<QuerySnapshot> getBudgets() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Savings Operations
  Future<void> addSavingsGoal(Map<String, dynamic> savingsData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    savingsData['userId'] = userId;
    await _firestore.collection('savings').add(savingsData);
  }

  Stream<QuerySnapshot> getSavingsGoals() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('savings')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
} 