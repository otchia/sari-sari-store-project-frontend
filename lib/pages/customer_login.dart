import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'customer_dashboard.dart';
import 'customer_register.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool _isPasswordVisible = false;

  // Animation controller for Google button
  late final AnimationController _googleBtnAnim;
  late final Animation<double> _googleBtnScale;

  @override
  void initState() {
    super.initState();
    _googleBtnAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _googleBtnScale =
        Tween<double>(begin: 1.0, end: 0.98).animate(_googleBtnAnim);
  }

  @override
  void dispose() {
    _googleBtnAnim.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- Email/Password login ----------------
  Future<void> loginCustomer() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/api/customer/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      setState(() => loading = false);

      final res = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _navigateToDashboard(res["customer"]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["message"] ?? "Invalid credentials"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------- Google Sign-In ----------------
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "489581687955-64gs1rj29ha4gb1vr0v4i9mdl95rb1pr.apps.googleusercontent.com",
  );

  Future<void> handleGoogleSignIn() async {
    setState(() => loading = true);
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => loading = false);
          return; // user cancelled
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google sign-in failed")));
        return;
      }

      final name = user.displayName ?? "";
      final email = user.email ?? "";
      final photoUrl = user.photoURL ?? "";

      // 1) Try Google login
      final loginResp = await http.post(
        Uri.parse("http://localhost:5000/api/customer/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "photoUrl": photoUrl}),
      );

      if (loginResp.statusCode == 200) {
        final res = jsonDecode(loginResp.body);
        setState(() => loading = false);
        _navigateToDashboard(res["customer"]);
        return;
      }

      // 2) If not found (404) -> register
      if (loginResp.statusCode == 404) {
        final registerResp = await http.post(
          Uri.parse("http://localhost:5000/api/customer/google-register"),
          headers: {"Content-Type": "application/json"},
          body:
              jsonEncode({"name": name, "email": email, "photoUrl": photoUrl}),
        );

        if (registerResp.statusCode == 201 || registerResp.statusCode == 200) {
          final res = jsonDecode(registerResp.body);
          setState(() => loading = false);
          _navigateToDashboard(res["customer"]);
          return;
        } else {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Register error: ${registerResp.body}")));
          return;
        }
      }

      // Other errors
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login error: ${loginResp.body}")));
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google sign-in error: $e")));
    }
  }

  // ---------------- Navigate to Dashboard ----------------
  void _navigateToDashboard(dynamic customer) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDashboardPage(
          customerName: customer["name"] ?? customer["email"] ?? "Customer",
          storeName: "Alyn Store",
        ),
      ),
    );
  }

  // ---------------- UI: Google button ----------------
  Widget _buildGoogleButton() {
    return GestureDetector(
      onTapDown: (_) => _googleBtnAnim.forward(),
      onTapUp: (_) => _googleBtnAnim.reverse(),
      onTapCancel: () => _googleBtnAnim.reverse(),
      onTap: handleGoogleSignIn,
      child: AnimatedBuilder(
        animation: _googleBtnScale,
        builder: (context, child) {
          return Transform.scale(scale: _googleBtnScale.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.g_mobiledata, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Sign in with Google',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.brown,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Build UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          "Customer Login",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
        ),
        centerTitle: true,
        elevation: 3,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront,
                        size: 80, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text(
                      "Welcome, Customer!",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown),
                    ),
                    const SizedBox(height: 24),

                    // Email field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: const Color(0xFFFFF3E0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: const Color(0xFFFFF3E0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email/Password login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : loginCustomer,
                        icon: const Icon(Icons.login),
                        label: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Login",
                                style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Google sign-in button
                    _buildGoogleButton(),
                    const SizedBox(height: 16),

                    // Register link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerRegisterPage()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register",
                        style: TextStyle(color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
