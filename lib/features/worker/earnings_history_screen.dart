import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  /// Fetch earnings data for the logged-in worker
  Future<Map<String, dynamic>> _fetchEarnings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final workerId = user.uid;

    QuerySnapshot completedJobs = await FirebaseFirestore.instance
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'completed')
        .get();

    if (completedJobs.docs.isEmpty) {
      return {'totalEarnings': 0, 'earningsByDate': {}};
    }

    double totalEarnings = 0;
    final Map<String, double> earningsByDate = {};

    for (var doc in completedJobs.docs) {
      final job = doc.data() as Map<String, dynamic>;

      // Ensure 'fare' exists and is valid
      if (job['fare'] != null && job['fare'] is double) {
        totalEarnings += job['fare'];

        final date = (job['createdAt'] as Timestamp).toDate().toString().split(' ')[0];
        earningsByDate[date] = (earningsByDate[date] ?? 0) + job['fare'];
      }
    }

    // Sort earnings by date
    final sortedEarningsByDate = Map.fromEntries(
      earningsByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return {'totalEarnings': totalEarnings, 'earningsByDate': sortedEarningsByDate};
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
                "Failed to load earnings. Please try again later.",
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Expanded(
                  child: earningsByDate.isEmpty
                      ? const Center(child: Text("No earnings history available."))
                      : ListView.builder(
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
