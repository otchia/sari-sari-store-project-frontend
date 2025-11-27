import 'package:flutter/material.dart';
import 'package:sarisite/widgets/customer_shop.dart';
import '../widgets/customer_navbar.dart';
import '../widgets/cart_widget.dart';
import '../widgets/customer_chat.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

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

  // Store status
  bool isPhysicalOpen = false;
  bool isOnlineOpen = false;
  bool isDeliveryActive = false;
  bool loadingStoreStatus = true;

  @override
  void initState() {
    super.initState();
    isLoggedIn = html.window.localStorage.containsKey('customerId');
    _fetchStoreStatus();

    // Refresh store status every 30 seconds
    Future.delayed(Duration.zero, () {
      _startPeriodicRefresh();
    });
  }

  void _startPeriodicRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) {
        _fetchStoreStatus();
        return true; // Continue the loop
      }
      return false; // Stop if widget is disposed
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchStoreStatus() async {
    try {
      // Get adminId from localStorage (should be set when admin logs in)
      String? adminId = html.window.localStorage['adminId'];

      // Fallback to hardcoded admin ID if not in localStorage
      if (adminId == null || adminId.isEmpty) {
        adminId =
            '690af31c412f5e89aa047d7d'; // Your actual admin ID from MongoDB
        print("⚠️ Using hardcoded adminId for customer dashboard");
      }

      print("🔵 Fetching store status for customer dashboard...");
      print("   Using adminId: $adminId");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings?adminId=$adminId"),
      );

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];
        final wasOpen = isPhysicalOpen || isOnlineOpen || isDeliveryActive;

        setState(() {
          isPhysicalOpen = data['physicalStatus'] ?? false;
          isOnlineOpen = data['onlineStatus'] ?? false;
          isDeliveryActive = data['deliveryStatus'] ?? false;
          loadingStoreStatus = false;
        });

        final isNowOpen = isPhysicalOpen || isOnlineOpen || isDeliveryActive;

        // If store closed while customer was browsing
        if (wasOpen && !isNowOpen && mounted) {
          _showStoreClosedWarning();
        }

        print("✅ Store status loaded for customer dashboard");
      } else {
        setState(() => loadingStoreStatus = false);
        print("❌ Failed to load store status");
      }
    } catch (e) {
      setState(() => loadingStoreStatus = false);
      print("❌ Error fetching store status: $e");
    }
  }

  void _showStoreClosedWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text("Store Has Closed"),
          ],
        ),
        content: const Text(
          "All store services are now closed. You can continue browsing, but orders cannot be placed at this time.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Continue Browsing",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.white,
            ),
            child: const Text("Exit"),
          ),
        ],
      ),
    );
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

          // Store Status Badges
          const SizedBox(width: 16),
          if (!loadingStoreStatus) ...[
            _buildStatusBadge(
              "Physical Store",
              isPhysicalOpen,
              Icons.store_mall_directory,
            ),
            const SizedBox(width: 8),
            _buildStatusBadge("Online", isOnlineOpen, Icons.shopping_cart),
            const SizedBox(width: 8),
            _buildStatusBadge(
              "Delivery",
              isDeliveryActive,
              Icons.delivery_dining,
            ),
          ] else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool isActive, IconData icon) {
    return Tooltip(
      message: isActive ? "$label is available" : "$label is closed",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isActive ? Colors.green : Colors.grey,
              isActive ? Colors.green.shade700 : Colors.grey.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        // Show shop with status banner if needed
        return Column(
          children: [
            // Status Banner
            if (!loadingStoreStatus && !isOnlineOpen)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade50],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade300, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Online Store Currently Closed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPhysicalOpen
                                ? "Visit our physical store for in-person shopping"
                                : "All services are currently unavailable",
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Shop Content
            Expanded(
              child: CustomerShopFixed(
                searchQuery: searchQuery,
                selectedCategory: selectedCategory,
              ),
            ),
          ],
        );
      case 1:
        // Check if user is logged in for cart access
        if (!isLoggedIn) {
          return _buildLoginRequiredPage(
            "Shopping Cart",
            Icons.shopping_cart,
            "Please log in to view your shopping cart and checkout",
          );
        }
        return Column(
          children: [
            // Delivery Status Banner
            if (!loadingStoreStatus && !isDeliveryActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade300, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivery Service Currently Unavailable",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPhysicalOpen
                                ? "Please visit our physical store for pickup"
                                : "All services are currently closed",
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Cart Content
            const Expanded(child: CartWidget()),
          ],
        );
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
        // Check if user is logged in for chat access
        if (!isLoggedIn) {
          return _buildLoginRequiredPage(
            "Chat with Admin",
            Icons.chat_bubble,
            "Please log in to chat with our support team",
          );
        }
        return const CustomerChat();
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

  // Login Required Page
  Widget _buildLoginRequiredPage(String title, IconData icon, String message) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6F00).withOpacity(0.2),
                    const Color(0xFFFFC107).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6F00).withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 80,
                color: const Color(0xFFFF6F00),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Login Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6F00).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Navigate to login page
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                    
                    // If user successfully logged in, update the state
                    if (result == true && mounted) {
                      setState(() {
                        isLoggedIn = html.window.localStorage.containsKey('customerId');
                      });
                      
                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Successfully logged in!',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Go to Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  'Look for the Login button in the sidebar',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
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
