import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sari-Sari Store App"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/customer-login');
              },
              icon: const Icon(Icons.login),
              label: const Text("Customer Google Sign-In"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-login');
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("Admin Login"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-register');
              },
              icon: const Icon(Icons.app_registration),
              label: const Text("Admin Register"),
            ),
          ],
        ),
      ),
    );
  }
}
