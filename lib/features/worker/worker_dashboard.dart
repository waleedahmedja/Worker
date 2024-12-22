import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/location_service.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final LocationService _locationService = LocationService();
  bool _isAvailable = false;
  late String workerId; // Store the worker's ID

  @override
  void initState() {
    super.initState();

    // Get the logged-in worker's ID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      workerId = user.uid;
      _locationService.startUpdatingLocation(workerId);
    } else {
      // Handle unauthenticated state (e.g., navigate to login screen)
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Toggles worker availability and updates Firestore
  Future<void> _toggleAvailability() async {
    setState(() {
      _isAvailable = !_isAvailable;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(workerId).update({
        'isAvailable': _isAvailable,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAvailable ? 'You are now available.' : 'You are now unavailable.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
      ),
      body: Column(
        children: [
          // Availability Toggle
          SwitchListTile(
            title: const Text("Set Availability"),
            value: _isAvailable,
            onChanged: (value) => _toggleAvailability(),
          ),
          const Divider(),

          // Navigation Options
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text("Job Requests"),
                  leading: const Icon(Icons.work_outline),
                  onTap: () {
                    Navigator.pushNamed(context, '/job-requests');
                  },
                ),
                ListTile(
                  title: const Text("Earnings"),
                  leading: const Icon(Icons.attach_money),
                  onTap: () {
                    Navigator.pushNamed(context, '/earnings');
                  },
                ),
                ListTile(
                  title: const Text("Job History"),
                  leading: const Icon(Icons.history),
                  onTap: () {
                    Navigator.pushNamed(context, '/job-history');
                  },
                ),
              ],
            ),
          ),

          // Active Job List
          const Divider(),
          const Text(
            "Active Jobs",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('workerId', isEqualTo: workerId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No active jobs.'));
                }

                final jobs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                          "Location: ${job['location'].latitude}, ${job['location'].longitude}"),
                      subtitle: Text("Status: ${job['status']}"),
                      trailing: job['status'] == 'pending'
                          ? ElevatedButton(
                              onPressed: () async {
                                // Accept Job
                                await FirebaseFirestore.instance
                                    .collection('jobs')
                                    .doc(jobs[index].id)
                                    .update({'status': 'in-progress'});
                              },
                              child: const Text("Accept Job"),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
