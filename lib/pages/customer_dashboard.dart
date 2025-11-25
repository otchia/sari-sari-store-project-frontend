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

  final List<String> categories = [
    "All",
    "Beverages",
    "Snacks",
    "Household",
    "Personal Care",
    "Other",
  ];

  String _getPageTitle() {
    switch (selectedIndex) {
      case 0:
        return "Shop";
      case 1:
        return "Shopping Cart";
      case 2:
        return "Wishlist";
      case 3:
        return "Purchase History";
      case 4:
        return "Order Status";
      case 5:
        return "Chat with Admin";
      default:
        return "Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // LEFT SIDEBAR (NEW NAVBAR)
          CustomerSidebar(
            storeName: widget.storeName,
            selectedIndex: selectedIndex,
            onIndexChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            isLoggedIn: isLoggedIn,
            onLoginSuccess: () {
              setState(() {
                isLoggedIn = true;
              });
            },
            onLogout: () {
              html.window.localStorage.remove('customerId');
              setState(() {
                isLoggedIn = false;
              });
            },
          ),

          // RIGHT SIDE CONTENT
          Expanded(
            child: Column(
              children: [
                // TOP BAR WITH SEARCH
                _buildTopBar(),

                // MAIN CONTENT AREA
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page Title
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPageTitle(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                if (isLoggedIn)
                  Text(
                    'Welcome back, ${widget.customerName}!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Search Bar (only show on Shop page)
          if (selectedIndex == 0) ...[
            Expanded(
              flex: 3,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              setState(() {
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Category Filter Button
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCategoryDialog,
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedCategory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _getPageWidget(),
        ),
      ),
    );
  }

  Widget _getPageWidget() {
    switch (selectedIndex) {
      case 0:
        return CustomerShopFixed(
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
        );
      case 1:
        return const CartWidget();
      case 2:
        return _placeholderPage(
          "Wishlist",
          Icons.favorite,
          "Your favorite items will appear here",
        );
      case 3:
        return _placeholderPage(
          "Purchase History",
          Icons.history,
          "View all your past purchases",
        );
      case 4:
        return _placeholderPage(
          "Order Status",
          Icons.local_shipping,
          "Track your current orders",
        );
      case 5:
        return _placeholderPage("Chat", Icons.chat, "Message the store admin");
      default:
        return _placeholderPage(
          "Dashboard",
          Icons.dashboard,
          "Welcome to your dashboard",
        );
    }
  }

  Widget _placeholderPage(String title, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: const Color(0xFFFFC107)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedCategory = cat;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFC107).withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFC107)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                color: isSelected
                                    ? const Color(0xFFFF6F00)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFFF6F00)
                                      : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFF6F00),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "All":
        return Icons.grid_view;
      case "Beverages":
        return Icons.local_drink;
      case "Snacks":
        return Icons.fastfood;
      case "Household":
        return Icons.home;
      case "Personal Care":
        return Icons.face;
      case "Other":
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
