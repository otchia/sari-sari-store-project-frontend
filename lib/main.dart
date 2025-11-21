import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/customer_login.dart';
import 'pages/admin_login.dart';
import 'pages/customer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Firebase (Web-safe)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SariSite App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.amber,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/shop',
      routes: {
        '/shop': (context) => const CustomerDashboardPage(
          customerName: "Guest",
          storeName: "Alyn's SariSite",
        ),  
        '/home': (context) => const LoginPage(),         
        '/customer-login': (context) => const CustomerLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}


/* Old main.dart
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SariSite App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.amber,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/customer-login': (context) => const CustomerLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}
*/
