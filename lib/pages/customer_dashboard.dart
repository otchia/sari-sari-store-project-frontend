import 'package:flutter/material.dart';
import 'package:sarisite/widgets/customer_shop.dart';
import '../widgets/customer_navbar.dart';
import 'customer_login.dart';

class CustomerDashboardPage extends StatefulWidget {
  final String customerName;
  final String storeName;

  const CustomerDashboardPage({
    super.key,
    required this.customerName,
    required this.storeName,
  });

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  int selectedIndex = 0;

  final List<String> menuItems = [
    "Account Settings",
    "Wishlist",
    "Purchase History",
    "Order Status",
    "Chat",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),

      // ✅ TOP NAVBAR WITHOUT BACK BUTTON
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: CustomerNavbar(
          storeName: widget.storeName,
          onCartPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🛒 Cart feature coming soon!")),
            );
          },
          onSortPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("📂 Sort feature coming soon!")),
            );
          },
        ),
      ),

      body: Row(
        children: [
          // ✅ SIDE NAVIGATION BAR
          Container(
            width: 220,
            color: const Color(0xFFFFC107),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 30),
                    for (int i = 0; i < menuItems.length; i++)
                      _buildNavButton(i, menuItems[i]),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomerLoginPage()),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ MAIN CONTENT AREA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildPageContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar button builder
  Widget _buildNavButton(int index, String label) {
    final bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            selectedIndex = index;
          });
        },
        icon: Icon(
          _getIconForLabel(label),
          color: isSelected ? Colors.redAccent : Colors.brown,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.redAccent : Colors.brown,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFFFFECB3) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  // Icon mapping for each label
  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Account Settings":
        return Icons.person;
      case "Wishlist":
        return Icons.favorite;
      case "Purchase History":
        return Icons.history;
      case "Order Status":
        return Icons.local_shipping;
      case "Chat":
        return Icons.chat;
      default:
        return Icons.help_outline;
    }
  }

  // Main content switching
  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return CustomerShop();
      case 1:
        return _placeholderPage("Wishlist");
      case 2:
        return _placeholderPage("Purchase History");
      case 3:
        return _placeholderPage("Order Status");
      case 4:
        return _placeholderPage("Chat with Admin");
      default:
        return _welcomeSection();
    }
  }

  // Welcome section
  Widget _welcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome, ${widget.customerName}!",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Use the sidebar to manage your account, view your wishlist, check your orders, or chat with the admin.",
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  // Placeholder for pages
  Widget _placeholderPage(String title) {
    return Center(
      child: Text(
        "$title Page (Coming Soon)",
        style: const TextStyle(
          fontSize: 22,
          color: Colors.brown,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
