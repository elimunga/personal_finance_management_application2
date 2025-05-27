import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String;
              final message = data['message'] as String;
              final createdAt = (data['createdAt'] as Timestamp).toDate();

              IconData icon;
              Color color;

              switch (type) {
                case 'budget_exceeded':
                  icon = Icons.warning;
                  color = Colors.red;
                  break;
                case 'budget_warning':
                  icon = Icons.warning_amber;
                  color = Colors.orange;
                  break;
                case 'reminder':
                  icon = Icons.notifications;
                  color = Colors.blue;
                  break;
                default:
                  icon = Icons.info;
                  color = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  title: Text(message),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                  ),
                  onTap: () {
                    // Handle notification tap
                    if (type == 'budget_exceeded' || type == 'budget_warning') {
                      Navigator.pushNamed(context, '/budgets');
                    } else if (type == 'reminder') {
                      Navigator.pushNamed(context, '/reminders');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 