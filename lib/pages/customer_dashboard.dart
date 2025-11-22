import 'package:flutter/material.dart';
import 'package:sarisite/widgets/customer_shop.dart';
import '../widgets/customer_navbar.dart';
import '../widgets/cart_widget.dart';
import 'dart:html' as html;

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
  String searchQuery = "";
  String selectedCategory = "All";
  late bool isLoggedIn;

  @override
  void initState() {
    super.initState();
    isLoggedIn = html.window.localStorage.containsKey('customerId');
  }

  final List<String> menuItems = [
    "Shop",
    "Cart", // ⭐ ADDED CART TAB
    "Wishlist",
    "Purchase History",
    "Order Status",
    "Chat",
  ];

  final List<String> categories = [
    "All",
    "Beverages",
    "Snacks",
    "Household",
    "Personal Care",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: CustomerNavbar(
          storeName: widget.storeName,
          isLoggedIn: isLoggedIn,
          onSortPressed: _showCategoryDialog,
          onSearchChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          onLoginSuccess: () {
            setState(() {
              isLoggedIn = true;
            });
          },
        ),
      ),
      body: Row(
        children: [
          // LEFT SIDEBAR MENU
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
                // Logout button (visible only if logged in)
                if (isLoggedIn) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        html.window.localStorage.remove('customerId');
                        setState(() {
                          isLoggedIn = false;
                        });
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

          // RIGHT SIDE CONTENT
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Shop":
        return Icons.storefront;
      case "Cart":
        return Icons.shopping_cart; // ⭐ CART ICON
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

  // ⭐ SWITCH BETWEEN SHOP + CART + OTHER PAGES
  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return CustomerShop(
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
        );
      case 1:
        return const CartWidget(); // ⭐ CART INSIDE DASHBOARD
      case 2:
        return _placeholderPage("Wishlist");
      case 3:
        return _placeholderPage("Purchase History");
      case 4:
        return _placeholderPage("Order Status");
      case 5:
        return _placeholderPage("Chat with Admin");
      default:
        return _welcomeSection();
    }
  }

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
      ],
    );
  }

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

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Category"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  title: Text(cat),
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
