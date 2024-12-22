import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get jobs => _jobs;
  bool get isLoading => _isLoading;

  static const String jobsCollection = 'jobs';
  static const String customerIdField = 'customerId';
  static const String createdAtField = 'createdAt';
  static const String statusField = 'status';

  /// Fetches jobs for a specific customer.
  Future<void> fetchJobsForCustomer(String customerId) async {
    if (customerId.isEmpty) {
      throw ArgumentError('Customer ID cannot be empty.');
    }

    _setLoading(true);

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(jobsCollection)
          .where(customerIdField, isEqualTo: customerId)
          .orderBy(createdAtField, descending: true)
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
          .collection(jobsCollection)
          .where(statusField, isEqualTo: 'pending')
          .orderBy(createdAtField, descending: true)
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

  /// Fetches jobs for a customer with pagination support.
  Future<void> fetchJobsForCustomerPaginated(
      String customerId, DocumentSnapshot? lastDocument, int limit) async {
    if (customerId.isEmpty || limit <= 0) {
      throw ArgumentError('Invalid arguments for paginated job fetch.');
    }

    _setLoading(true);

    try {
      Query query = _firestore
          .collection(jobsCollection)
          .where(customerIdField, isEqualTo: customerId)
          .orderBy(createdAtField, descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();

      _jobs.addAll(snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    } catch (e) {
      debugPrint('Error fetching paginated jobs for customer: $e');
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
