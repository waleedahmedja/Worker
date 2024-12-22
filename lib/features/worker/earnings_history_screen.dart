import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key}); // Use super parameter for `Key`

  /// Fetch earnings data for the logged-in worker
  Future<Map<String, dynamic>> _fetchEarnings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final workerId = user.uid; // Get the logged-in worker's UID

    QuerySnapshot completedJobs = await FirebaseFirestore.instance
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'completed')
        .get();

    double totalEarnings = 0;
    final Map<String, double> earningsByDate = {};

    for (var doc in completedJobs.docs) {
      final job = doc.data() as Map<String, dynamic>;
      totalEarnings += job['fare'];

      // Group earnings by date
      final date = (job['createdAt'] as Timestamp).toDate().toString().split(' ')[0];
      earningsByDate[date] = (earningsByDate[date] ?? 0) + job['fare'];
    }

    return {'totalEarnings': totalEarnings, 'earningsByDate': earningsByDate};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earnings History")),
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

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No earnings data available."));
          }

          final earnings = snapshot.data!;
          final earningsByDate = earnings['earningsByDate'] as Map<String, double>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Earnings: \$${earnings['totalEarnings'].toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleLarge, // Updated API
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: earningsByDate.length,
                    itemBuilder: (context, index) {
                      final date = earningsByDate.keys.elementAt(index);
                      final amount = earningsByDate[date]!;
                      return ListTile(
                        title: Text("Date: $date"),
                        trailing: Text("Earnings: \$${amount.toStringAsFixed(2)}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
