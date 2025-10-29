import 'package:flutter/material.dart';
import '../services/google_signin_service.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final GoogleSignInService _googleService = GoogleSignInService();
  String? userName;
  String? userEmail;
  String? userPhoto;

  Future<void> handleGoogleSignIn() async {
    final account = await _googleService.signInWithGoogle();

    if (account != null) {
      setState(() {
        userName = account.displayName;
        userEmail = account.email;
        userPhoto = account.photoUrl;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Google Sign-In")),
      body: Center(
        child: userName == null
            ? ElevatedButton.icon(
                onPressed: handleGoogleSignIn,
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userPhoto != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(userPhoto!),
                      radius: 40,
                    ),
                  const SizedBox(height: 10),
                  Text("Welcome, $userName!",
                      style: const TextStyle(fontSize: 20)),
                  Text(userEmail ?? ''),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _googleService.signOut();
                      setState(() {
                        userName = null;
                        userEmail = null;
                        userPhoto = null;
                      });
                    },
                    child: const Text("Sign out"),
                  ),
                ],
              ),
      ),
    );
  }
}
