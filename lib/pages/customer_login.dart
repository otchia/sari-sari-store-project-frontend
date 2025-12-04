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
        print("✅ Email/Password login successful!");
        print("   Full response: $res");
        print("   Customer data in response: ${res["customer"]}");

        _showSuccessModal();
        await Future.delayed(const Duration(seconds: 2));

        // Close the success modal
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss success modal

        // Now navigate to dashboard with store check
        await _navigateToDashboard(res["customer"]);
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

      // Step 1: Firebase Authentication
      print("🔵 Step 1: Starting Google Sign-In...");
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print("❌ User cancelled Google Sign-In");
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
        print("❌ No user returned from Firebase");
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

      print("✅ Firebase auth successful");
      print("   Name: $name");
      print("   Email: $email");

      if (email.isEmpty) {
        print("❌ Email is empty");
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google account has no email")),
        );
        return;
      }

      // Step 2: Try to login to backend
      print("🔵 Step 2: Attempting backend login...");
      final loginResp = await http.post(
        Uri.parse("http://localhost:5000/api/customer/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "photoUrl": photoUrl}),
      );

      print("   Login response status: ${loginResp.statusCode}");
      print("   Login response body: ${loginResp.body}");

      if (loginResp.statusCode == 200) {
        print("✅ Google login successful!");
        setState(() => loading = false);
        final res = jsonDecode(loginResp.body);
        print("   Customer data: ${res["customer"]}");
        _showSuccessModal();
        await Future.delayed(const Duration(seconds: 2));

        // Close the success modal
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss success modal

        // Now navigate to dashboard with store check
        await _navigateToDashboard(res["customer"]);
        return;
      }

      // Step 3: Register if not found
      if (loginResp.statusCode == 404) {
        print("🔵 Step 3: User not found, registering...");
        final registerResp = await http.post(
          Uri.parse("http://localhost:5000/api/customer/google-register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": name,
            "email": email,
            "photoUrl": photoUrl,
          }),
        );

        print("   Register response status: ${registerResp.statusCode}");
        print("   Register response body: ${registerResp.body}");

        if (registerResp.statusCode == 201 || registerResp.statusCode == 200) {
          print("✅ Google registration successful!");
          setState(() => loading = false);
          final res = jsonDecode(registerResp.body);
          print("   Customer data: ${res["customer"]}");
          _showSuccessModal();
          await Future.delayed(const Duration(seconds: 2));

          // Close the success modal
          if (!mounted) return;
          Navigator.of(context).pop(); // Dismiss success modal

          // Now navigate to dashboard with store check
          await _navigateToDashboard(res["customer"]);
          return;
        } else {
          print("❌ Registration failed");
          setState(() => loading = false);
          final errorMsg =
              jsonDecode(registerResp.body)["message"] ?? "Registration failed";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration error: $errorMsg"),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      // If we reach here, login failed with a status other than 200 or 404
      print("❌ Login failed with status: ${loginResp.statusCode}");
      setState(() => loading = false);
      final errorMsg = jsonDecode(loginResp.body)["message"] ?? "Login failed";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login error: $errorMsg"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e, stackTrace) {
      print("❌ Error during Google Sign-In:");
      print("   Error: $e");
      print("   Stack trace: $stackTrace");
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google sign-in error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------- Check Store Status ----------------
  Future<bool> _checkStoreStatus() async {
    try {
      print("🔵 Checking store status before login...");
      print("===============================================");

      // 🔧 CONFIGURATION: Get your admin ID from MongoDB and paste it here
      // You can get this by logging in as admin and checking the console
      String? adminId = html.window.localStorage['adminId'];

      // If no adminId in localStorage, use this hardcoded one
      if (adminId == null || adminId.isEmpty) {
        adminId =
            '690af31c412f5e89aa047d7d'; // Your actual admin ID from MongoDB
        print("⚠️ Using hardcoded adminId from code");
      } else {
        print("✅ Found adminId in localStorage: $adminId");
      }

      print("   Will check store status with adminId: $adminId");

      print("===============================================");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings?adminId=$adminId"),
      );

      print("");
      print("📡 API Response:");
      print("   Status: ${response.statusCode}");
      print("   Body: ${response.body}");
      print("");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];
        final isPhysicalOpen = data['physicalStatus'] ?? false;
        final isOnlineOpen = data['onlineStatus'] ?? false;
        final isDeliveryActive = data['deliveryStatus'] ?? false;

        final isAnyServiceOpen =
            isPhysicalOpen || isOnlineOpen || isDeliveryActive;

        print("🏪 Store Status:");
        print("   Physical Store: ${isPhysicalOpen ? '✅ OPEN' : '❌ CLOSED'}");
        print("   Online Store: ${isOnlineOpen ? '✅ OPEN' : '❌ CLOSED'}");
        print(
          "   Delivery: ${isDeliveryActive ? '✅ AVAILABLE' : '❌ UNAVAILABLE'}",
        );
        print("");
        print(
          "🔍 Result: ${isAnyServiceOpen ? '✅ ALLOW LOGIN' : '❌ BLOCK LOGIN'}",
        );
        print("===============================================");

        return isAnyServiceOpen;
      } else if (response.statusCode == 404) {
        print("❌ Admin ID not found in database!");
        print("   The adminId '$adminId' doesn't exist");
        print("   Please check your admin ID and try again");
        print("===============================================");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Configuration Error: Invalid admin ID. Please contact support.",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return false;
      } else {
        print("❌ Failed to fetch store status (${response.statusCode})");
        print("   Response: ${response.body}");
        print("===============================================");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to verify store status. Please try again."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      print("❌ EXCEPTION during store status check:");
      print("   Error: $e");
      print("===============================================");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // ---------------- Navigate to Dashboard ----------------
  Future<void> _navigateToDashboard(dynamic customer) async {
    print("🔵 Navigating to dashboard...");
    print("   Raw customer data: $customer");
    print("   Customer type: ${customer.runtimeType}");

    // DEBUG: Print all keys in customer object
    if (customer is Map) {
      print("   Available keys in customer: ${customer.keys.toList()}");
      print("   customer['id'] = ${customer['id']}");
      print("   customer['_id'] = ${customer['_id']}");
      print("   customer['customerId'] = ${customer['customerId']}");
    }

    // Backend might return "id", "_id", or nested in customer object
    final customerId =
        customer?["_id"]?.toString() ??
        customer?["id"]?.toString() ??
        customer?["customerId"]?.toString() ??
        "";
    final customerName = (customer?["name"] ?? customer?["email"] ?? "Customer")
        .toString();

    print("   Parsed Customer ID: $customerId");
    print("   Parsed Customer Name: $customerName");

    // Check if store is open before allowing access
    final isStoreOpen = await _checkStoreStatus();

    if (!isStoreOpen) {
      print("❌ Store is closed, denying access");

      // Show store closed modal
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
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
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store_outlined,
                            color: Colors.red.shade700,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Store Currently Closed",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "All services are temporarily unavailable.\nPlease check back later!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
      return;
    }

    // Save userId to localStorage safely
    print("   🔍 Customer ID to save: '$customerId'");
    if (customerId.isNotEmpty) {
      html.window.localStorage['customerId'] = customerId;
      print("   ✅ Customer ID saved to localStorage");

      // Verify it was saved
      final savedId = html.window.localStorage['customerId'];
      print("   🔍 Verification - Retrieved from localStorage: '$savedId'");
    } else {
      print("   ❌ Customer ID is empty, not saved to localStorage");
    }

    if (!mounted) return;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC107), Color(0xFFFFE082)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 450),
                margin: EdgeInsets.all(isMobile ? 16 : 24),
                child: Card(
                  elevation: isMobile ? 10 : 20,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.orange[50]!],
                      ),
                    ),
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with gradient background
                        Container(
                          padding: EdgeInsets.all(isMobile ? 18 : 24),
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
                          child: Icon(
                            Icons.shopping_bag,
                            size: isMobile ? 40 : 50,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
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
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          "Sign in to continue shopping",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
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
                        SizedBox(height: isMobile ? 16 : 20),
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
                        SizedBox(height: isMobile ? 20 : 28),
                        // Email/Password login button
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 50 : 56,
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
                                : Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
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
                        SizedBox(height: isMobile ? 20 : 24),
                        // Google sign-in button
                        _buildGoogleButton(),
                        SizedBox(height: isMobile ? 20 : 24),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isMobile ? 14 : 15,
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
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: const Color(0xFFFF6F00),
                                  fontSize: isMobile ? 14 : 15,
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
