import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  /// Registers a new user with email and password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String cnic,
    required String role, // "customer" or "worker"
  }) async {
    try {
      // Create Firebase user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Store user details in Firestore
      await _firestoreService.addUser(_user!.uid, {
        'name': name,
        'cnic': cnic,
        'email': email,
        'role': role,
        'uid': _user!.uid,
        'createdAt': Timestamp.now(),
        'location': null,
        'isAvailable': role == 'worker' ? false : null,
      });

      // Save FCM token
      await FCMService.saveFCMToken(_user!.uid); // Use the class name to call the static method

      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign-up: $e');
      rethrow;
    }
  }

  /// Logs in a user with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Fetch user profile from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      _userData = userDoc.data() as Map<String, dynamic>;

      // Save FCM token
      await FCMService.saveFCMToken(_user!.uid); // Use the class name to call the static method

      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign-in: $e');
      rethrow;
    }
  }

  /// Logs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign-out: $e');
      rethrow;
    }
  }
}
