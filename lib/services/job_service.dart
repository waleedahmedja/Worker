import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore field and collection names as constants
  static const String jobsCollection = 'jobs';
  static const String customerIdField = 'customerId';
  static const String workerIdField = 'workerId';
  static const String createdAtField = 'createdAt';
  static const String statusField = 'status';

  /// Creates a new job in the Firestore `jobs` collection.
  Future<void> createJob(Map<String, dynamic> jobData) async {
    if (jobData.isEmpty) {
      throw ArgumentError('Job data cannot be empty.');
    }
    try {
      await _firestore.collection(jobsCollection).add(jobData);
    } catch (e) {
      print('Error creating job: $e');
      rethrow;
    }
  }

  /// Updates a job in the Firestore `jobs` collection.
  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    if (jobId.isEmpty || updates.isEmpty) {
      throw ArgumentError('Job ID or updates cannot be empty.');
    }
    try {
      await _firestore.collection(jobsCollection).doc(jobId).update(updates);
    } catch (e) {
      print('Error updating job: $e');
      rethrow;
    }
  }

  /// Fetches all jobs for a specific user (customer or worker).
  Future<QuerySnapshot> getJobsByUser(String userId, String field) async {
    if (userId.isEmpty || field.isEmpty) {
      throw ArgumentError('User ID or field cannot be empty.');
    }
    try {
      return await _firestore
          .collection(jobsCollection)
          .where(field, isEqualTo: userId)
          .orderBy(createdAtField, descending: true)
          .get();
    } catch (e) {
      print('Error fetching jobs for $userId: $e');
      rethrow;
    }
  }

  /// Fetches jobs for a user with pagination support.
  Future<QuerySnapshot> getJobsByUserPaginated(
      String userId, String field, DocumentSnapshot? lastDoc, int limit) async {
    if (userId.isEmpty || field.isEmpty || limit <= 0) {
      throw ArgumentError('Invalid arguments for paginated job fetch.');
    }
    try {
      Query query = _firestore
          .collection(jobsCollection)
          .where(field, isEqualTo: userId)
          .orderBy(createdAtField, descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      return await query.get();
    } catch (e) {
      print('Error fetching paginated jobs for $userId: $e');
      rethrow;
    }
  }

  /// Fetches a specific job by its ID.
  Future<DocumentSnapshot> getJobById(String jobId) async {
    if (jobId.isEmpty) {
      throw ArgumentError('Job ID cannot be empty.');
    }
    try {
      return await _firestore.collection(jobsCollection).doc(jobId).get();
    } catch (e) {
      print('Error fetching job by ID: $e');
      rethrow;
    }
  }

  /// Updates the status of a job.
  Future<void> updateJobStatus(String jobId, String status) async {
    if (jobId.isEmpty || status.isEmpty) {
      throw ArgumentError('Job ID or status cannot be empty.');
    }
    try {
      await _firestore
          .collection(jobsCollection)
          .doc(jobId)
          .update({statusField: status});
    } catch (e) {
      print('Error updating job status: $e');
      rethrow;
    }
  }

  /// Deletes a job.
  Future<void> deleteJob(String jobId) async {
    if (jobId.isEmpty) {
      throw ArgumentError('Job ID cannot be empty.');
    }
    try {
      await _firestore.collection(jobsCollection).doc(jobId).delete();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }

  /// Implements a soft delete by marking the job as deleted.
  Future<void> softDeleteJob(String jobId) async {
    if (jobId.isEmpty) {
      throw ArgumentError('Job ID cannot be empty.');
    }
    try {
      await _firestore.collection(jobsCollection).doc(jobId).update({'deleted': true});
    } catch (e) {
      print('Error performing soft delete on job: $e');
      rethrow;
    }
  }
}
