import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/worker/auth_screen.dart';
import 'features/worker/worker_dashboard.dart';
import 'features/worker/job_requests_screen.dart';
import 'features/worker/earnings_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM notifications
  await FCMService.initializeNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CleanMatch Worker',
        theme: ThemeData(primarySwatch: Colors.green),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthScreen(),
          '/worker-dashboard': (context) => const WorkerDashboard(),
          '/job-requests': (context) => const JobRequestsScreen(),
          '/earnings': (context) => const EarningsScreen(),
        },
      ),
    );
  }
}
