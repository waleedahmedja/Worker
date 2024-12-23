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
  bool _isLoading = false; // Loading state for toggling availability
  String? workerId;

  @override
  void initState() {
    super.initState();
    _initializeWorker();
  }

  Future<void> _initializeWorker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        workerId = user.uid;
      });
      _locationService.startUpdatingLocation(workerId!);
    } else {
      // Redirect unauthenticated users to login screen
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    }
  }

  /// Toggles worker availability and updates Firestore
  Future<void> _toggleAvailability() async {
    if (workerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _isAvailable = !_isAvailable;
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (workerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            onChanged: _isLoading ? null : (value) => _toggleAvailability(),
          ),
          const Divider(),

          // Navigation Options
          Expanded(
            flex: 1,
            child: ListView(
              children: [
                _buildNavigationTile(
                  title: "Job Requests",
                  icon: Icons.work_outline,
                  onTap: () => Navigator.pushNamed(context, '/job-requests'),
                ),
                _buildNavigationTile(
                  title: "Earnings",
                  icon: Icons.attach_money,
                  onTap: () => Navigator.pushNamed(context, '/earnings'),
                ),
                _buildNavigationTile(
                  title: "Job History",
                  icon: Icons.history,
                  onTap: () => Navigator.pushNamed(context, '/job-history'),
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
            flex: 2,
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
                    final location = job['location'];
                    final status = job['status'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          "Location: ${location != null ? '${location.latitude}, ${location.longitude}' : 'Unavailable'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Status: $status"),
                        trailing: status == 'pending'
                            ? ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobs[index].id)
                                      .update({'status': 'in-progress'});
                                },
                                child: const Text("Accept Job"),
                              )
                            : null,
                      ),
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

  /// Helper to build navigation tiles
  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
