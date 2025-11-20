import 'package:flutter/material.dart';

class CustomerNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String storeName;
  final VoidCallback? onSortPressed;
  final ValueChanged<String>? onSearchChanged;

  const CustomerNavbar({
    super.key,
    required this.storeName,
    this.onSortPressed,
    this.onSearchChanged,
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
          Text(
            storeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown,
              fontSize: 20,
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

              // Account
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account Settings coming soon!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.account_circle, color: Colors.brown),
                label: const Text(
                  "Account",
                  style: TextStyle(color: Colors.brown),
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
