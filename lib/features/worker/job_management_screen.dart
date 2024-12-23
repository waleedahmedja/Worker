import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobManagementScreen extends StatelessWidget {
  const JobManagementScreen({super.key});

  /// Confirms payment for a specific job
  Future<void> _confirmPayment(BuildContext context, String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'paymentStatus': 'completed',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment: $e')),
      );
    }
  }

  /// Fetches the authenticated worker's ID
  String? _getWorkerId(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Navigate to login screen if not authenticated
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return null;
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final workerId = _getWorkerId(context);
    if (workerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Jobs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('workerId', isEqualTo: workerId)
            .where('status', isEqualTo: 'in-progress')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active jobs."));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final isPaymentCompleted = job['paymentStatus'] == 'completed';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Job Location: ${job['location'].latitude}, ${job['location'].longitude}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Fare: \$${job['fare'] ?? 'N/A'}"),
                      Text("Notes: ${job['customerNotes'] ?? 'No notes'}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isPaymentCompleted
                            ? null
                            : () => _confirmPayment(context, jobs[index].id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaymentCompleted
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          isPaymentCompleted
                              ? "Payment Completed"
                              : "Confirm Payment",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
