import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  /// Fetches the authenticated worker's ID
  String _getWorkerId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
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
    final workerId = _getWorkerId();

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
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text("Location: ${job['location'].latitude}, ${job['location'].longitude}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fare: \$${job['fare']}"),
                      Text("Notes: ${job['customerNotes'] ?? 'No notes provided'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptJob(context, jobs[index].id, workerId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectJob(context, jobs[index].id),
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
