import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection and field names as constants
  static const String usersCollection = 'users';
  static const String roleField = 'role';

  /// Adds a user to the Firestore `users` collection.
  Future<void> addUser(String uid, Map<String, dynamic> userData) async {
    if (uid.isEmpty || userData.isEmpty) {
      throw ArgumentError(
          'Invalid arguments: UID or user data cannot be empty.');
    }
    try {
      await _firestore.collection(usersCollection).doc(uid).set(userData);
      print('User added successfully: $uid');
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  /// Updates a user document in the Firestore `users` collection.
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    if (uid.isEmpty || updates.isEmpty) {
      throw ArgumentError('Invalid arguments: UID or updates cannot be empty.');
    }
    try {
      await _firestore.collection(usersCollection).doc(uid).update(updates);
      print('User updated successfully: $uid');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Fetches a user's data by UID from the Firestore `users` collection.
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

  /// Deletes a user document in the Firestore `users` collection.
  Future<void> deleteUser(String uid) async {
    if (uid.isEmpty) {
      throw ArgumentError('Invalid UID.');
    }
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
      print('User deleted successfully: $uid');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Fetches all users by a specific role from Firestore.
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    if (role.isEmpty) {
      throw ArgumentError('Role cannot be empty.');
    }
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection(usersCollection)
          .where(roleField, isEqualTo: role)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      rethrow;
    }
  }

  /// Fetches users by role with pagination.
  Future<List<Map<String, dynamic>>> getUsersByRolePaginated(
      String role, DocumentSnapshot? lastDoc, int limit) async {
    if (role.isEmpty || limit <= 0) {
      throw ArgumentError('Invalid arguments for paginated role fetch.');
    }
    try {
      Query query = _firestore
          .collection(usersCollection)
          .where(roleField, isEqualTo: role)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching paginated users by role: $e');
      rethrow;
    }
  }
}
