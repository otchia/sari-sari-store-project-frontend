import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  final String storeName;

  const AdminDashboardPage({super.key, required this.storeName});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isStoreOpen = true;
  int selectedIndex = 0; // ✅ keeps track of which tab is active

  final List<String> menuItems = [
    "Store Status",
    "Orders",
    "Inventory",
    "Chat",
    "Analytics",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: Text(
          "${widget.storeName}'s Admin Dashboard",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        centerTitle: true,
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
                      Navigator.pop(context);
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

  // ✅ Sidebar button builder
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  // ✅ Icon mapping for each label
  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Store Status":
        return Icons.store;
      case "Orders":
        return Icons.list_alt;
      case "Inventory":
        return Icons.inventory_2;
      case "Chat":
        return Icons.chat;
      case "Analytics":
        return Icons.analytics;
      default:
        return Icons.help_outline;
    }
  }

  // ✅ Main content that changes when a button is clicked
  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return _buildStoreStatus();
      case 1:
        return _placeholderPage("Orders");
      case 2:
        return _placeholderPage("Inventory");
      case 3:
        return _placeholderPage("Chat");
      case 4:
        return _placeholderPage("Analytics");
      default:
        return _buildStoreStatus();
    }
  }

  // ✅ Store Status content
  Widget _buildStoreStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Store Status",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              "Store is currently:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            Switch(
              value: isStoreOpen,
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
              onChanged: (value) {
                setState(() {
                  isStoreOpen = value;
                });
              },
            ),
            Text(
              isStoreOpen ? "Open" : "Closed",
              style: TextStyle(
                fontSize: 18,
                color: isStoreOpen ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          "Status changes will be reflected in real-time once connected to backend.",
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  // ✅ Placeholder pages for other sections
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
