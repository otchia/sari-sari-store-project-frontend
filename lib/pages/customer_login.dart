import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
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
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _googleBtnScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(_googleBtnAnim);
  }

  @override
  void dispose() {
    _googleBtnAnim.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- SUCCESS MODAL ----------------
  void _showSuccessModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: 0.8 + (anim1.value * 0.2),
            child: Center(
              child: Card(
                color: Colors.white,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 80),
                      SizedBox(height: 16),
                      Text(
                        "Login Successful!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Redirecting to your dashboard...",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Email/Password login ----------------
  Future<void> loginCustomer() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
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
        _showSuccessModal();
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
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
          return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Google sign-in failed")));
        return;
      }

      // Safely convert values to String
      final name = (user.displayName ?? "").toString();
      final email = (user.email ?? "").toString();
      final photoUrl = (user.photoURL ?? "").toString();

      if (email.isEmpty) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google account has no email")),
        );
        return;
      }

      // BACKEND LOGIN
      final loginResp = await http.post(
        Uri.parse("http://localhost:5000/api/customer/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "photoUrl": photoUrl}),
      );

      if (loginResp.statusCode == 200) {
        final res = jsonDecode(loginResp.body);
        _showSuccessModal();
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _navigateToDashboard(res["customer"]);
        return;
      }

      // REGISTER IF NOT FOUND
      if (loginResp.statusCode == 404) {
        final registerResp = await http.post(
          Uri.parse("http://localhost:5000/api/customer/google-register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": name,
            "email": email,
            "photoUrl": photoUrl,
          }),
        );

        if (registerResp.statusCode == 201 || registerResp.statusCode == 200) {
          final res = jsonDecode(registerResp.body);
          _showSuccessModal();
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          _navigateToDashboard(res["customer"]);
        }
      }

      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login error: ${loginResp.body}")));
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in error: $e")));
    }
  }

  // ---------------- Navigate to Dashboard ----------------
  void _navigateToDashboard(dynamic customer) {
    final customerId = customer?["_id"]?.toString() ?? "";
    final customerName = (customer?["name"] ?? customer?["email"] ?? "Customer")
        .toString();

    // Save userId to localStorage safely
    if (customerId.isNotEmpty) {
      html.window.localStorage['customerId'] = customerId;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDashboardPage(
          customerName: customerName,
          storeName: "Alyn's Store",
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/google_logo.png",
                height: 28,
                width: 28,
              ),
              const SizedBox(width: 16),
              const Text(
                "Continue with Google",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFFC107), const Color(0xFFFFE082)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.orange[50]!],
                      ),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with gradient background
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF6F00)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              color: const Color(0xFFFF6F00),
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue shopping",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Email field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            hintText: "Enter your email",
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFFFF6F00),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFC107),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password field
                        TextField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Enter your password",
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: Color(0xFFFF6F00),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFC107),
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Email/Password login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: loading ? null : loginCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              elevation: 4,
                              shadowColor: Colors.orange.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Google sign-in button
                        _buildGoogleButton(),
                        const SizedBox(height: 24),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomerRegisterPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFFFF6F00),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
