import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  /// Fetch earnings data for the authenticated worker
  Future<Map<String, dynamic>> _fetchEarnings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final workerId = user.uid; // Get logged-in worker's UID

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('earnings')
        .doc(workerId)
        .get();

    if (!doc.exists) {
      return {}; // Return empty data if no earnings document exists
    }

    return doc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earnings")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchEarnings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No earnings data available."));
          }

          var earnings = snapshot.data!;
          return ListView(
            children: [
              _buildEarningsTile("Daily Earnings", earnings['daily']),
              _buildEarningsTile("Weekly Earnings", earnings['weekly']),
              _buildEarningsTile("Monthly Earnings", earnings['monthly']),
              ListTile(
                title: const Text("Total Earnings"),
                trailing: Text("\$${earnings['total'] ?? 0.0}"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper to build an earnings tile with calculated totals
  Widget _buildEarningsTile(String title, dynamic data) {
    if (data == null || data is! List) return ListTile(title: Text(title), trailing: const Text("\$0.00"));

    final total = data.reduce((a, b) => a + b);
    return ListTile(title: Text(title), trailing: Text("\$${total.toStringAsFixed(2)}"));
  }
}
