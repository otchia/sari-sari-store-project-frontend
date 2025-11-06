import 'package:flutter/material.dart';

class CustomerNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String storeName;
  final VoidCallback? onSortPressed;
  final VoidCallback? onCartPressed;
  final ValueChanged<String>? onSearchChanged;

  const CustomerNavbar({
    super.key,
    required this.storeName,
    this.onSortPressed,
    this.onCartPressed,
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
          // 🏪 Store Name
          Text(
            storeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown,
              fontSize: 20,
            ),
          ),

          // 🔍 Search Bar
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📂 Sort & 🛒 Cart buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: onSortPressed,
                icon: const Icon(Icons.category, color: Colors.brown),
                label: const Text(
                  "Sort by Category",
                  style: TextStyle(color: Colors.brown),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onCartPressed,
                icon: const Icon(Icons.shopping_cart, color: Colors.brown),
                label: const Text(
                  "Cart",
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
