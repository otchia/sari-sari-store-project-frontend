import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  final String storeName; // ✅ accept the store name

  const AdminDashboardPage({super.key, required this.storeName}); // ✅ required parameter

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isStoreOpen = true; // example switch value

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
          // ✅ Side Navigation Bar
          Container(
            width: 220,
            color: const Color(0xFFFFC107),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation buttons
                Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildNavButton(Icons.store, "Store Status"),
                    _buildNavButton(Icons.list_alt, "Orders"),
                    _buildNavButton(Icons.inventory_2, "Inventory"),
                    _buildNavButton(Icons.chat, "Chat"),
                    _buildNavButton(Icons.analytics, "Analytics"),
                  ],
                ),
                // Logout Button
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

          // ✅ Main Dashboard Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Store Status",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextButton.icon(
        onPressed: () {
          // placeholder for navigation
        },
        icon: Icon(icon, color: Colors.brown),
        label: Text(
          label,
          style: const TextStyle(color: Colors.brown, fontSize: 16),
        ),
      ),
    );
  }
}
