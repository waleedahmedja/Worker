import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get jobs => _jobs;
  bool get isLoading => _isLoading;

  /// Fetches jobs for a specific customer.
  Future<void> fetchJobsForCustomer(String customerId) async {
    _setLoading(true);

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      _jobs = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching jobs for customer: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches jobs that are pending for workers to accept.
  Future<void> fetchJobsForWorker() async {
    _setLoading(true);

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      _jobs = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching jobs for workers: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the loading state and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
