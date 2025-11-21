import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminStoreSettings extends StatefulWidget {
  const AdminStoreSettings({super.key});

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

  // ================= FETCH STORE SETTINGS =================
  Future<void> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];

        setState(() {
          storeNameController.text = data['storeName'] ?? '';
          storeHoursController.text = data['storeHours'] ?? '';

          isPhysicalOpen = data['isPhysicalOpen'] ?? false;
          isOnlineOpen = data['isOnlineOpen'] ?? false;
          isDeliveryActive = data['isDeliveryActive'] ?? false;

          loading = false;
        });
      }
    } catch (e) {
      print("Fetch Error: $e");
    }
  }

  // ================= UPDATE STORE SETTINGS =================
  Future<void> updateSettings() async {
    setState(() => saving = true);

    final body = {
      "storeName": storeNameController.text,
      "storeHours": storeHoursController.text,
      "isPhysicalOpen": isPhysicalOpen,
      "isOnlineOpen": isOnlineOpen,
      "isDeliveryActive": isDeliveryActive,
    };

    try {
      final response = await http.put(
        Uri.parse("http://localhost:5000/api/store-settings"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Store settings updated!")),
        );
      }
    } catch (e) {
      print("Error updating: $e");
    }

    setState(() => saving = false);
  }

  // ================= AUTO-SAVE FOR TOGGLES =================
  void autoSaveToggle() {
    updateSettings();
  }

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Store Settings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),

              const SizedBox(height: 20),

              // ---------- STORE NAME ----------
              const Text("Store Name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(
                controller: storeNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- STORE HOURS (Time Picker) ----------
              const Text("Store Hours",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(
                controller: storeHoursController,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: pickStoreHours,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ---------- TOGGLES ----------
              _buildToggle("Physical Store Open", isPhysicalOpen, (v) {
                setState(() => isPhysicalOpen = v);
                autoSaveToggle();
              }),

              _buildToggle("Online Store Open", isOnlineOpen, (v) {
                setState(() => isOnlineOpen = v);
                autoSaveToggle();
              }),

              _buildToggle("Delivery Service Active", isDeliveryActive, (v) {
                setState(() => isDeliveryActive = v);
                autoSaveToggle();
              }),

              const SizedBox(height: 30),

              // ---------- SAVE BUTTON ----------
              Center(
                child: ElevatedButton(
                  onPressed: updateSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---------- SAVING OVERLAY ----------
        if (saving)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // =============== TIME RANGE PICKER ===============
  void pickStoreHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );

    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
    );

    if (end == null) return;

    setState(() {
      storeHoursController.text =
          "${start.format(context)} - ${end.format(context)}";
    });
  }

  // =============== TOGGLE BUILDER ===============
  Widget _buildToggle(String label, bool value, Function(bool) onChange) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: Switch(
          value: value,
          activeThumbColor: Colors.green,
          onChanged: onChange,
        ),
      ),
    );
  }
}
