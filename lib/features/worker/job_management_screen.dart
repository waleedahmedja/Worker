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
  String _getWorkerId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final workerId = _getWorkerId();

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
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    "Job Location: ${job['location'].latitude}, ${job['location'].longitude}",
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fare: \$${job['fare']}"),
                      Text("Notes: ${job['customerNotes'] ?? 'No notes'}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmPayment(context, jobs[index].id),
                    child: const Text("Confirm Payment"),
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
