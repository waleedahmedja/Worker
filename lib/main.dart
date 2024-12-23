import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Feature Imports
import 'features/worker/auth_screen.dart';
import 'features/worker/worker_dashboard.dart';
import 'features/worker/job_requests_screen.dart';
import 'features/worker/earnings_screen.dart';

// Provider Imports
import 'providers/auth_provider.dart' as local_auth_provider;
import 'providers/job_provider.dart';

// Service Imports
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize FCM notifications
    await FCMService.initializeNotifications();
  } catch (e) {
    debugPrint("Error initializing Firebase or FCM: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => local_auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CleanMatch Worker',
        theme: ThemeData(primarySwatch: Colors.green),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const AuthStateWrapper(),
        routes: {
          '/worker-dashboard': (context) => const WorkerDashboard(),
          '/job-requests': (context) => const JobRequestsScreen(),
          '/earnings': (context) => const EarningsScreen(),
        },
      ),
    );
  }
}

/// Widget to dynamically switch between AuthScreen and WorkerDashboard
class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a splash screen while checking auth state
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          // Show an error message if something goes wrong
          return const Scaffold(
            body: Center(child: Text("Error loading app. Please restart.")),
          );
        }

        // Show WorkerDashboard if user is authenticated, otherwise show AuthScreen
        return snapshot.data != null
            ? const WorkerDashboard()
            : const AuthScreen();
      },
    );
  }
}

/// Splash Screen Widget for loading state
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
