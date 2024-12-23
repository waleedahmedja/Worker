import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  /// Fetches the authenticated worker's ID
  String? _getWorkerId(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return null;
    }
    return user.uid;
  }

  /// Accepts a job by updating its status and assigning the worker ID
  Future<void> _acceptJob(BuildContext context, String jobId, String workerId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'in-progress',
        'workerId': workerId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job accepted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting job: $e')),
      );
    }
  }

  /// Rejects a job by resetting its worker ID and keeping it as pending
  Future<void> _rejectJob(BuildContext context, String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'workerId': null,
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job rejected.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting job: $e')),
      );
    }
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
      appBar: AppBar(title: const Text("Job Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No job requests available."));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final location = job['location'];
              final fare = job['fare'] ?? 'N/A';
              final notes = job['customerNotes'] ?? 'No notes provided';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location: ${location != null ? "${location.latitude}, ${location.longitude}" : 'Unavailable'}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Fare: \$${fare}"),
                      Text("Notes: $notes"),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _acceptJob(context, jobs[index].id, workerId),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Accept"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _rejectJob(context, jobs[index].id),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text("Reject"),
                          ),
                        ],
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
