import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names as constants
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String earningsCollection = 'earnings';

  /// Adds a user to Firestore.
  Future<void> addUser(String uid, Map<String, dynamic> userData) async {
    if (uid.isEmpty || userData.isEmpty) {
      throw ArgumentError('Invalid arguments: UID or userData cannot be empty.');
    }
    try {
      await _firestore.collection(usersCollection).doc(uid).set(userData);
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  /// Fetches a user document by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    if (uid.isEmpty) {
      throw ArgumentError('Invalid UID.');
    }
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection(usersCollection).doc(uid).get();
      return userDoc.data();
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  /// Creates a new job in Firestore.
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

  /// Updates the status of a job.
  Future<void> updateJobStatus(String jobId, String status) async {
    if (jobId.isEmpty || status.isEmpty) {
      throw ArgumentError('Job ID or status cannot be empty.');
    }
    try {
      await _firestore.collection(jobsCollection).doc(jobId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating job status: $e');
      rethrow;
    }
  }

  /// Updates worker earnings.
  Future<void> addWorkerEarnings(String workerId, double amount) async {
    if (workerId.isEmpty || amount <= 0) {
      throw ArgumentError('Worker ID must be valid, and amount must be positive.');
    }
    try {
      DocumentReference earningsRef =
          _firestore.collection(earningsCollection).doc(workerId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(earningsRef);

        if (!snapshot.exists) {
          transaction.set(earningsRef, {
            'daily': [amount],
            'weekly': [amount],
            'monthly': [amount],
            'total': amount,
          });
        } else {
          Map<String, dynamic> data =
              snapshot.data() as Map<String, dynamic>;
          List<double> daily = List<double>.from(data['daily'] ?? []);
          List<double> weekly = List<double>.from(data['weekly'] ?? []);
          List<double> monthly = List<double>.from(data['monthly'] ?? []);
          double total = data['total'] ?? 0.0;

          // Maintain list size limits (e.g., max 30 entries for daily)
          if (daily.length >= 30) daily.removeAt(0);
          if (weekly.length >= 52) weekly.removeAt(0);
          if (monthly.length >= 12) monthly.removeAt(0);

          daily.add(amount);
          weekly.add(amount);
          monthly.add(amount);
          total += amount;

          transaction.update(earningsRef, {
            'daily': daily,
            'weekly': weekly,
            'monthly': monthly,
            'total': total,
          });
        }
      });
    } catch (e) {
      print('Error updating worker earnings: $e');
      rethrow;
    }
  }
}
