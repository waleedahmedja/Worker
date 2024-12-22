import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a user to the Firestore `users` collection.
  ///
  /// [uid]: The unique user ID.
  /// [userData]: A map containing user data to store in Firestore.
  Future<void> addUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
      print('User added successfully: $uid');
    } catch (e) {
      print('Error adding user: $e');
      rethrow; // Pass the error to the caller
    }
  }

  /// Updates a user document in the Firestore `users` collection.
  ///
  /// [uid]: The unique user ID.
  /// [updates]: A map containing fields to update.
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
      print('User updated successfully: $uid');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Fetches a user's data by UID from the Firestore `users` collection.
  ///
  /// [uid]: The unique user ID.
  /// Returns: A map containing user data if found, otherwise `null`.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  /// Deletes a user document in the Firestore `users` collection.
  ///
  /// [uid]: The unique user ID.
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('User deleted successfully: $uid');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Fetches all users by a specific role from Firestore.
  ///
  /// [role]: The role to filter by (e.g., `worker` or `customer`).
  /// Returns: A list of users with the specified role.
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      rethrow;
    }
  }
}
