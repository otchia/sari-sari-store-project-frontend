import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../widgets/admin_inventory.dart';
import '../widgets/admin_store_settings.dart';

class AdminDashboardPage extends StatefulWidget {
  final String storeName;

  const AdminDashboardPage({super.key, required this.storeName});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isPhysicalOpen = false;
  bool isOnlineOpen = false;
  bool isDeliveryActive = false;
  int selectedIndex = 0;
  String adminUsername = '';
  bool loadingSettings = true;

  final List<String> menuItems = [
    "Store Status",
    "Orders",
    "Inventory",
    "Chat",
    "Analytics",
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _fetchStoreSettings();
  }

  void _loadAdminInfo() {
    try {
      adminUsername = html.window.localStorage['adminUsername'] ?? 'Admin';
      print("👤 Loaded admin username: $adminUsername");
    } catch (e) {
      print("Error loading admin info: $e");
      adminUsername = 'Admin';
    }
  }

  Future<void> _fetchStoreSettings({bool showRefreshIndicator = false}) async {
    if (showRefreshIndicator) {
      setState(() => loadingSettings = true);
    }

    try {
      final adminId = html.window.localStorage['adminId'];
      if (adminId == null || adminId.isEmpty) {
        print("❌ No adminId found");
        setState(() => loadingSettings = false);
        return;
      }

      print("🔵 Fetching store settings for dashboard...");
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings?adminId=$adminId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];
        setState(() {
          isPhysicalOpen = data['physicalStatus'] ?? false;
          isOnlineOpen = data['onlineStatus'] ?? false;
          isDeliveryActive = data['deliveryStatus'] ?? false;
          loadingSettings = false;
        });
        print("✅ Store settings loaded for dashboard");

        // Show a brief success indicator
        if (showRefreshIndicator && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Dashboard updated!"),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      } else {
        setState(() => loadingSettings = false);
        print("❌ Failed to load store settings");
      }
    } catch (e) {
      setState(() => loadingSettings = false);
      print("❌ Error fetching store settings: $e");
    }
  }

  // Refresh settings when coming back to Store Status tab
  void _onTabChanged(int index) {
    setState(() => selectedIndex = index);
    if (index == 0) {
      _fetchStoreSettings(); // Refresh when viewing Store Status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Modern Sidebar
          _buildModernSidebar(),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildPageContent(),
                    ),
                  ),
                ),
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getIconForLabel(menuItems[selectedIndex]),
            size: 28,
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 12),
          Text(
            menuItems[selectedIndex],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const Spacer(),
          // Store Status Badges
          if (!loadingSettings) ...[
            _buildStatusBadge(
              "Physical",
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

  Widget _buildModernSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Store Header
          _buildStoreHeader(),

          const SizedBox(height: 30),

          // Navigation Menu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < menuItems.length; i++)
                    _buildNavButton(i, menuItems[i]),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Logout Button
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.storeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              adminUsername.isNotEmpty ? adminUsername : 'Admin Panel',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await _showLogoutModal();
          },
          icon: const Icon(Icons.logout, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFD32F2F),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutModal() async {
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
                        "Logout Successful!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "See you again soon!",
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

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.pop(context);
    }
  }

  Widget _buildStatusBadge(String label, bool isActive, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildNavButton(int index, String label) {
    final bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabChanged(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForLabel(label),
                  color: isSelected ? const Color(0xFFD32F2F) : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFD32F2F)
                          : Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Store Status":
        return Icons.store_rounded;
      case "Orders":
        return Icons.shopping_bag_rounded;
      case "Inventory":
        return Icons.inventory_2_rounded;
      case "Chat":
        return Icons.chat_bubble_rounded;
      case "Analytics":
        return Icons.analytics_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return AdminStoreSettings(
          onSettingsChanged: () {
            print("🔄 Settings changed, refreshing dashboard...");
            _fetchStoreSettings(showRefreshIndicator: true);
          },
        );
      case 1:
        return _placeholderPage("Orders", Icons.shopping_bag_rounded);
      case 2:
        return const AdminInventory();
      case 3:
        return _placeholderPage("Chat", Icons.chat_bubble_rounded);
      case 4:
        return _placeholderPage("Analytics", Icons.analytics_rounded);
      default:
        return _buildStoreStatus();
    }
  }

  Widget _buildStoreStatus() {
    if (loadingSettings) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
        ),
      );
    }

    final anyStoreOpen = isPhysicalOpen || isOnlineOpen;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Overall Store Status Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD32F2F).withOpacity(0.1),
                  const Color(0xFFB71C1C).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: anyStoreOpen
                              ? [Colors.green, Colors.green.shade700]
                              : [Colors.grey, Colors.grey.shade700],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (anyStoreOpen ? Colors.green : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        anyStoreOpen ? Icons.lock_open : Icons.lock,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Store Status Overview",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            anyStoreOpen
                                ? "Your store is currently accepting orders"
                                : "All services are currently closed",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Individual Status Cards
          _buildStatusCard(
            title: "Physical Store",
            subtitle: "In-person shopping at your location",
            icon: Icons.store_mall_directory,
            isActive: isPhysicalOpen,
            activeColor: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            title: "Online Store",
            subtitle: "Accept orders through the app",
            icon: Icons.shopping_cart,
            isActive: isOnlineOpen,
            activeColor: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            title: "Delivery Service",
            subtitle: "Offer delivery to customers",
            icon: Icons.delivery_dining,
            isActive: isDeliveryActive,
            activeColor: Colors.orange,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "To change these settings, go to 'Store Status' in the sidebar menu.",
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? HSLColor.fromColor(
                            activeColor,
                          ).withLightness(0.3).toColor()
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? "ACTIVE" : "CLOSED",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD32F2F).withOpacity(0.1),
                  const Color(0xFFB71C1C).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: const Color(0xFFD32F2F).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "$title Page",
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF212121),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Coming Soon",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
