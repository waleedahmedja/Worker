import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new job in the Firestore `jobs` collection.
  ///
  /// [jobData]: A map containing job details to be stored.
  Future<void> createJob(Map<String, dynamic> jobData) async {
    try {
      await _firestore.collection('jobs').add(jobData);
    } catch (e) {
      print('Error creating job: $e');
      rethrow;
    }
  }

  /// Updates a job in the Firestore `jobs` collection.
  ///
  /// [jobId]: The unique job document ID.
  /// [updates]: A map containing the fields to update.
  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update(updates);
    } catch (e) {
      print('Error updating job: $e');
      rethrow;
    }
  }

  /// Fetches all jobs for a specific user (customer or worker).
  ///
  /// [userId]: The ID of the user (customerId or workerId).
  /// [field]: The Firestore field to query by (`customerId` or `workerId`).
  /// Returns: A list of job documents as QuerySnapshot.
  Future<QuerySnapshot> getJobsByUser(String userId, String field) async {
    try {
      return await _firestore
          .collection('jobs')
          .where(field, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      print('Error fetching jobs for $userId: $e');
      rethrow;
    }
  }

  /// Fetches a specific job by its ID.
  ///
  /// [jobId]: The unique job document ID.
  /// Returns: A document snapshot of the job.
  Future<DocumentSnapshot> getJobById(String jobId) async {
    try {
      return await _firestore.collection('jobs').doc(jobId).get();
    } catch (e) {
      print('Error fetching job by ID: $e');
      rethrow;
    }
  }

  /// Updates the status of a job.
  ///
  /// [jobId]: The unique job document ID.
  /// [status]: The new status to set (e.g., `pending`, `in-progress`, `completed`).
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({'status': status});
    } catch (e) {
      print('Error updating job status: $e');
      rethrow;
    }
  }

  /// Deletes a job.
  ///
  /// [jobId]: The unique job document ID.
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }
}
