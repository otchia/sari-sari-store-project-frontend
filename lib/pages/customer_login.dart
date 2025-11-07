import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'customer_dashboard.dart';
import 'dart:convert'; // 🔹 needed for jsonEncode/jsonDecode
import 'package:http/http.dart' as http; // 🔹 needed for http.post

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: "489581687955-64gs1rj29ha4gb1vr0v4i9mdl95rb1pr.apps.googleusercontent.com",
);

  String? userName;
  String? userEmail;
  String? userPhoto;

Future<void> handleGoogleSignIn() async {
  try {
    UserCredential userCredential;

    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user != null) {
      // 🔹 Send Google user info to your backend (no token yet)
      final response = await http.post(
        Uri.parse("http://localhost:5000/api/customer/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": user.displayName,
          "email": user.email,
          "photoUrl": user.photoURL,
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        print("✅ Backend response: $res");

        setState(() {
          userName = res["customer"]["name"];
          userEmail = res["customer"]["email"];
          userPhoto = res["customer"]["photoUrl"];
        });

        // ✅ Animated success card
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

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDashboardPage(
              customerName: res["customer"]["name"] ?? "Customer",
              storeName: "Alyn Store",
            ),
          ),
        );
      } else {
        print("❌ Backend error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Sign-In Error: $e")),
    );
  }
}

  Future<void> handleSignOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    setState(() {
      userName = null;
      userEmail = null;
      userPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          "Customer Login",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront,
                        size: 80, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    Text(
                      userName == null
                          ? "Welcome, Customer!"
                          : "Welcome, $userName!",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userName == null
                          ? "Sign in to access your sari-sari store account."
                          : userEmail ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    if (userName == null)
                      ElevatedButton.icon(
                        onPressed: handleGoogleSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text("Sign in with Google"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (userPhoto != null)
                            CircleAvatar(
                              backgroundImage: NetworkImage(userPhoto!),
                              radius: 40,
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: handleSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text("Sign out"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back to Home",
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
