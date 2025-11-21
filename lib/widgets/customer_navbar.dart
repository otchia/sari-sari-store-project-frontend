import 'package:flutter/material.dart';
import '../pages/customer_login.dart' show CustomerLoginPage;


class CustomerNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String storeName;
  final VoidCallback? onSortPressed;
  final ValueChanged<String>? onSearchChanged;
  final bool isLoggedIn;
  final VoidCallback? onLoginSuccess;

  const CustomerNavbar({
    super.key,
    required this.storeName,
    this.onSortPressed,
    this.onSearchChanged,
    this.isLoggedIn = false,
    this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFC107),
      elevation: 4,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Store name
          Padding(padding: const EdgeInsets.only(left: 20),
            child: Text(
              storeName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                fontSize: 20,
              ),
            ),
          ),

          // Search bar
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Buttons (Cart removed)
          Row(
            children: [
              // Sort
              TextButton.icon(
                onPressed: onSortPressed,
                icon: const Icon(Icons.category, color: Colors.brown),
                label: const Text(
                  "Sort",
                  style: TextStyle(color: Colors.brown),
                ),
              ),

              const SizedBox(width: 8),

              // Account / Logout
              TextButton.icon(
                onPressed: () async {
                  if (!isLoggedIn) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerLoginPage()
                      ),
                    );
                    if (result == true && onLoginSuccess != null) {
                      onLoginSuccess!();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Account Settings coming soon!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isLoggedIn ? Icons.person : Icons.account_circle,
                  color: Colors.brown,
                  ),
                label: Text(
                  isLoggedIn ? "Account" : "Login",
                  style: const TextStyle(color: Colors.brown),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
