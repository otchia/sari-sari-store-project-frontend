import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  // Initialize GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Sign in with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }
}
