import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

class AdminStoreSettings extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const AdminStoreSettings({super.key, this.onSettingsChanged});

  @override
  State<AdminStoreSettings> createState() => _AdminStoreSettingsState();
}

class _AdminStoreSettingsState extends State<AdminStoreSettings> {
  TextEditingController storeNameController = TextEditingController();
  TextEditingController storeHoursController = TextEditingController();

  bool isPhysicalOpen = false;
  bool isOnlineOpen = false;
  bool isDeliveryActive = false;

  bool loading = true;
  bool saving = false;
  String? adminId;

  // ================= GET ADMIN ID FROM LOCALSTORAGE =================
  String? getAdminId() {
    try {
      return html.window.localStorage['adminId'];
    } catch (e) {
      print("Error getting adminId: $e");
      return null;
    }
  }

  // ================= FETCH STORE SETTINGS =================
  Future<void> fetchSettings() async {
    setState(() => loading = true);

    adminId = getAdminId();

    if (adminId == null || adminId!.isEmpty) {
      print("❌ No adminId found in localStorage");
      setState(() => loading = false);
      // Use addPostFrameCallback to show snackbar after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Admin ID not found. Please login again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
      return;
    }

    print("🔵 Fetching store settings for adminId: $adminId");

    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings?adminId=$adminId"),
      );

      print("   Response status: ${response.statusCode}");
      print("   Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];

        setState(() {
          storeNameController.text = data['storeName'] ?? '';
          storeHoursController.text = data['storeHours'] ?? '9:00AM - 6:00PM';

          // Backend uses physicalStatus, onlineStatus, deliveryStatus
          isPhysicalOpen = data['physicalStatus'] ?? false;
          isOnlineOpen = data['onlineStatus'] ?? false;
          isDeliveryActive = data['deliveryStatus'] ?? false;

          loading = false;
        });

        print("✅ Store settings loaded successfully");
      } else {
        setState(() => loading = false);
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Failed to load settings';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      }
    } catch (e) {
      print("❌ Fetch Error: $e");
      setState(() => loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Network error: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  // ================= UPDATE STORE SETTINGS =================
  Future<void> updateSettings() async {
    if (adminId == null || adminId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin ID not found. Please login again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => saving = true);

    print("🔵 Updating store settings...");

    final body = {
      "adminId": adminId,
      "storeName": storeNameController.text.trim(),
      "storeHours": storeHoursController.text.trim(),
      "physicalStatus": isPhysicalOpen,
      "onlineStatus": isOnlineOpen,
      "deliveryStatus": isDeliveryActive,
    };

    print("   Request body: $body");

    try {
      final response = await http.put(
        Uri.parse("http://localhost:5000/api/store-settings"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("   Response status: ${response.statusCode}");
      print("   Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Settings updated successfully");

        // Notify dashboard of changes
        if (widget.onSettingsChanged != null) {
          widget.onSettingsChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Store settings updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $errorMsg"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("❌ Error updating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => saving = false);
  }

  // ================= TOGGLE SPECIFIC STATUS (OPTIMIZED) =================
  Future<void> toggleStatus(String statusType, bool value) async {
    if (adminId == null || adminId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin ID not found. Please login again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    print("🔵 Toggling $statusType to $value");

    final body = {"adminId": adminId, "statusType": statusType, "value": value};

    try {
      final response = await http.patch(
        Uri.parse("http://localhost:5000/api/store-settings/toggle-status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ Status toggled successfully");

        // Notify dashboard of changes
        if (widget.onSettingsChanged != null) {
          widget.onSettingsChanged!();
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Toggle failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $errorMsg"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("❌ Error toggling status: $e");
    }
  }

  // ================= AUTO-SAVE FOR TOGGLES =================
  void autoSaveToggle(String statusType, bool value) {
    toggleStatus(statusType, value);
  }

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading store settings...",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.brown,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Store Settings",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      Text(
                        "Manage your store information and status",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ---------- STORE INFORMATION CARD ----------
              _buildSectionCard(
                title: "Store Information",
                icon: Icons.store,
                children: [
                  _buildTextField(
                    label: "Store Name",
                    controller: storeNameController,
                    icon: Icons.storefront,
                    hint: "Enter your store name",
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Store Hours",
                    controller: storeHoursController,
                    icon: Icons.access_time,
                    hint: "Select store operating hours",
                    readOnly: true,
                    onTap: pickStoreHours,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.edit_calendar,
                        color: Colors.brown,
                      ),
                      onPressed: pickStoreHours,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------- STORE STATUS CARD ----------
              _buildSectionCard(
                title: "Store Status",
                icon: Icons.toggle_on,
                subtitle:
                    "Toggle these switches to control your store availability",
                children: [
                  _buildModernToggle(
                    title: "Physical Store",
                    subtitle: "In-person shopping at your location",
                    icon: Icons.store_mall_directory,
                    value: isPhysicalOpen,
                    activeColor: Colors.green,
                    onChanged: (v) {
                      setState(() => isPhysicalOpen = v);
                      autoSaveToggle('physicalStatus', v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernToggle(
                    title: "Online Store",
                    subtitle: "Accept orders through the app",
                    icon: Icons.shopping_cart,
                    value: isOnlineOpen,
                    activeColor: Colors.blue,
                    onChanged: (v) {
                      setState(() => isOnlineOpen = v);
                      autoSaveToggle('onlineStatus', v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernToggle(
                    title: "Delivery Service",
                    subtitle: "Offer delivery to customers",
                    icon: Icons.delivery_dining,
                    value: isDeliveryActive,
                    activeColor: Colors.orange,
                    onChanged: (v) {
                      setState(() => isDeliveryActive = v);
                      autoSaveToggle('deliveryStatus', v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ---------- SAVE BUTTON ----------
              Center(
                child: ElevatedButton.icon(
                  onPressed: saving ? null : updateSettings,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    saving ? "Saving..." : "Save All Changes",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.brown.withOpacity(0.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),

        // ---------- SAVING OVERLAY ----------
        if (saving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Saving changes...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =============== TIME RANGE PICKER ===============
  void pickStoreHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );

    if (end == null) return;

    setState(() {
      storeHoursController.text =
          "${start.format(context)} - ${end.format(context)}";
    });
  }

  // =============== SECTION CARD BUILDER ===============
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.brown.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.brown, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // =============== TEXT FIELD BUILDER ===============
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.brown),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.brown, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  // =============== MODERN TOGGLE BUILDER ===============
  Widget _buildModernToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color activeColor,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value ? activeColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: value ? activeColor.darken() : Colors.grey[700],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Transform.scale(
          scale: 1.1,
          child: Switch(
            value: value,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.5),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// =============== COLOR EXTENSION FOR DARKEN ===============
extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
