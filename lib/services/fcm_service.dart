import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initializes FCM and local notifications
  static Future<void> initializeNotifications() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("Notification clicked: ${response.payload}");
        // Handle navigation or logic here if needed
      },
    );

    // Request notification permissions for iOS/Android
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Listen for messages in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        if (message.notification != null) {
          _showNotification(
            message.notification!.title ?? "New Notification",
            message.notification!.body ?? "You have a new message.",
          );
        }
      } catch (e) {
        print("Error handling foreground message: $e");
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Displays a local notification
  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel for app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  /// Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      print('Background Message Received: ${message.notification?.title}');
    } catch (e) {
      print("Error handling background message: $e");
    }
  }

  /// Saves the FCM token for a user in Firestore
  static Future<void> saveFCMToken(String uid) async {
    if (uid.isEmpty) {
      print("Invalid UID for saving FCM token");
      return;
    }

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      // Retrieve the existing token from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>; // Explicit cast
        if (userData['fcmToken'] == token) {
          print("Token is already up-to-date.");
          return;
        }
      }

      // Update the token if it's different
      await _firestore.collection('users').doc(uid).update({'fcmToken': token});
      print("FCM Token updated for user $uid: $token");
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
