import 'package:flutter/material.dart';
import 'pages/customer_login.dart';
import 'pages/admin_login.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mob Project',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),            // <- now home page
        '/customer-login': (context) => const CustomerLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}
