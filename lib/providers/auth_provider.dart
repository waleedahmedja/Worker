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

  static const String usersCollection = 'users';

  /// Registers a new user with email and password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String cnic,
    required String role, // "customer" or "worker"
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty || cnic.isEmpty) {
      throw ArgumentError('All fields are required.');
    }
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

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

      await FCMService.saveFCMToken(_user!.uid);

      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign-up: $e');
      rethrow;
    }
  }

  /// Logs in a user with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required.');
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Listen to real-time user data
      listenToUserData(_user!.uid);

      await FCMService.saveFCMToken(_user!.uid);

      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign-in: $e');
      rethrow;
    }
  }

  /// Listens to user data for real-time updates.
  void listenToUserData(String uid) {
    _firestore.collection(usersCollection).doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data() as Map<String, dynamic>;
        notifyListeners();
      }
    });
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

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
}
