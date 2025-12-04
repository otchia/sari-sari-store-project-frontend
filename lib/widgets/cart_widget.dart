import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';

class CartWidget extends StatefulWidget {
  const CartWidget({super.key});

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  List<dynamic> cartItems = [];
  bool loading = true;
  bool isDeliveryAvailable = false;
  bool loadingDeliveryStatus = true;

  @override
  void initState() {
    super.initState();
    // Fetch cart first, then check delivery (so we have cart items to extract adminId from)
    fetchCart().then((_) {
      _checkDeliveryAvailability();
    });

    cartNotifier.addListener(() {
      fetchCart();
    });
  }

  // ================= CHECK DELIVERY AVAILABILITY =================
  Future<void> _checkDeliveryAvailability() async {
    setState(() => loadingDeliveryStatus = true);

    try {
      // Try to get adminId from multiple sources
      String? adminId = html.window.localStorage['adminId'];

      // If no adminId in localStorage, try to get from cart items
      if ((adminId == null || adminId.isEmpty) && cartItems.isNotEmpty) {
        try {
          // Try to get adminId from first product in cart
          final firstProduct = cartItems[0]['productId'];
          adminId = firstProduct['adminId']?.toString();
          print("📦 Got adminId from cart product: $adminId");
        } catch (e) {
          print("⚠️ Could not extract adminId from cart: $e");
        }
      }

      // If still no adminId, use hardcoded one (same as customer_dashboard.dart)
      if (adminId == null || adminId.isEmpty) {
        adminId =
            '690af31c412f5e89aa047d7d'; // Your actual admin ID from MongoDB
        print("⚠️ Using hardcoded adminId for cart delivery check");
      }

      print("🔵 Checking delivery availability for adminId: $adminId");
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/store-settings?adminId=$adminId"),
      );

      print("   Store settings response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['settings'];
        final deliveryStatus = data['deliveryStatus'] ?? false;
        setState(() {
          isDeliveryAvailable = deliveryStatus;
          loadingDeliveryStatus = false;
        });
        print("✅ Delivery available: $isDeliveryAvailable");
      } else {
        print("❌ Failed to load store settings");
        setState(() {
          isDeliveryAvailable = false;
          loadingDeliveryStatus = false;
        });
      }
    } catch (e) {
      print("❌ Error checking delivery: $e");
      setState(() {
        isDeliveryAvailable = false;
        loadingDeliveryStatus = false;
      });
    }
  }

  Future<void> fetchCart() async {
    setState(() => loading = true);

    final userId = html.window.localStorage['customerId'];
    print("🔵 Fetching cart for userId: $userId");

    if (userId == null) {
      print("❌ No customerId in localStorage");
      setState(() {
        cartItems = [];
        loading = false;
      });
      return;
    }

    try {
      print("   Cart API: http://localhost:5000/api/cart/$userId");
      final res = await http.get(
        Uri.parse("http://localhost:5000/api/cart/$userId"),
      );
      print("   Cart response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final items = decoded['items'] ?? [];

        // Filter out soft-deleted items
        final activeItems = items.where((i) => i['removed'] != true).toList();

        setState(() {
          cartItems = activeItems;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // DELETE item
  Future<void> removeItem(String productId) async {
    final userId = html.window.localStorage['customerId'];
    if (userId == null) return;

    try {
      final req = http.Request(
        'DELETE',
        Uri.parse("http://localhost:5000/api/cart/item"),
      );
      req.headers.addAll({"Content-Type": "application/json"});
      req.body = jsonEncode({"userId": userId, "productId": productId});
      final res = await req.send();
      if (res.statusCode == 200) {
        fetchCart();
        cartNotifier.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item removed from cart"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  // PATCH quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    final userId = html.window.localStorage['customerId'];
    if (userId == null) return;

    try {
      final req = http.Request(
        'PATCH',
        Uri.parse("http://localhost:5000/api/cart/item"),
      );
      req.headers.addAll({"Content-Type": "application/json"});
      req.body = jsonEncode({
        "userId": userId,
        "productId": productId,
        "quantity": quantity,
      });
      final res = await req.send();
      if (res.statusCode == 200) {
        fetchCart();
        cartNotifier.value++;
      }
    } catch (_) {}
  }

  // ================= CHECKOUT FUNCTION =================
  Future<void> checkout() async {
    final bool hasOutOfStock = cartItems.any(
      (item) => (item['productId']['stock'] ?? 0) == 0,
    );

    if (hasOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Remove out-of-stock items before checkout."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if any item quantity exceeds stock
    final bool hasExceededStock = cartItems.any((item) {
      final stock = item['productId']['stock'] ?? 0;
      final qty = item['quantity'] ?? 0;
      return qty > stock;
    });

    if (hasExceededStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Some items exceed available stock. Please adjust quantities.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = html.window.localStorage['customerId'];
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to checkout"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your cart is empty"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show checkout dialog
    await _showCheckoutDialog(userId);
  }

  // ================= CHECKOUT DIALOG =================
  Future<void> _showCheckoutDialog(String userId) async {
    // Refresh delivery availability when opening checkout
    await _checkDeliveryAvailability();

    // Default to pickup, or force pickup if delivery unavailable
    String deliveryType = isDeliveryAvailable ? "pickup" : "pickup";
    String paymentMethod = ""; // Must be selected (AC4)

    // Delivery fields (AC5, AC6)
    final TextEditingController addressController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    bool isProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Auto-switch to pickup if delivery becomes unavailable
          if (deliveryType == "delivery" && !isDeliveryAvailable) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setDialogState(() {
                deliveryType = "pickup";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Delivery is unavailable. Switched to pickup."),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_checkout,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Checkout",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                Text(
                                  "Complete your order details",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: Colors.grey[700],
                              tooltip: 'Close',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Order Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Order Summary",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "${cartItems.length} items • Total: ₱${subtotal.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contact Phone (Optional but recommended)
                      const Text(
                        "Contact Number",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          hintText: "Enter your phone number (optional)",
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFFFF6F00),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // Delivery unavailable warning
                      if (!isDeliveryAvailable)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Delivery is currently unavailable",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Delivery Type Selection (AC1)
                      const Text(
                        "Delivery Type",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDeliveryOption(
                              context,
                              setDialogState,
                              deliveryType,
                              "pickup",
                              "Pick-up",
                              Icons.store,
                              "Collect from store",
                              isProcessing,
                              (value) {
                                setDialogState(() => deliveryType = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDeliveryOption(
                              context,
                              setDialogState,
                              deliveryType,
                              "delivery",
                              "Delivery",
                              Icons.delivery_dining,
                              isDeliveryAvailable
                                  ? "Deliver to address"
                                  : "Unavailable",
                              isProcessing || !isDeliveryAvailable,
                              (value) {
                                if (isDeliveryAvailable) {
                                  setDialogState(() => deliveryType = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Delivery Fields (AC5, AC6)
                      if (deliveryType == "delivery") ...[
                        const Text(
                          "Delivery Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Delivery Address
                        TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: "Delivery Address *",
                            hintText: "Enter your complete address",
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Color(0xFFFF6F00),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        // Contact Number
                        TextField(
                          controller: contactController,
                          decoration: InputDecoration(
                            labelText: "Contact Number *",
                            hintText: "Phone number for delivery",
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Color(0xFFFF6F00),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),

                        // Delivery Notes
                        TextField(
                          controller: notesController,
                          decoration: InputDecoration(
                            labelText: "Delivery Notes (Optional)",
                            hintText: "Landmarks, special instructions, etc.",
                            prefixIcon: const Icon(
                              Icons.note,
                              color: Color(0xFFFF6F00),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Payment Method Selection (AC3, AC4)
                      const Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentOption(
                              context,
                              setDialogState,
                              paymentMethod,
                              "gcash",
                              "GCash",
                              Icons.account_balance_wallet,
                              Colors.blue,
                              isProcessing,
                              (value) {
                                setDialogState(() => paymentMethod = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPaymentOption(
                              context,
                              setDialogState,
                              paymentMethod,
                              "cash",
                              "Cash",
                              Icons.payments,
                              Colors.green,
                              isProcessing,
                              (value) {
                                setDialogState(() => paymentMethod = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      // Validate (AC4, AC6)
                                      if (paymentMethod.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please select a payment method",
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      if (deliveryType == "delivery") {
                                        if (addressController.text
                                                .trim()
                                                .isEmpty ||
                                            contactController.text
                                                .trim()
                                                .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please fill in all delivery fields",
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }
                                      }

                                      // Process order
                                      setDialogState(() => isProcessing = true);
                                      final orderData = await _processCheckout(
                                        userId,
                                        deliveryType,
                                        paymentMethod,
                                        addressController.text.trim(),
                                        contactController.text.trim(),
                                        notesController.text.trim(),
                                        phoneController.text.trim(),
                                      );
                                      setDialogState(
                                        () => isProcessing = false,
                                      );

                                      // Close checkout dialog first, then show success modal
                                      if (mounted && orderData != null) {
                                        Navigator.pop(
                                          context,
                                        ); // Close checkout dialog
                                        // Show success modal after dialog is closed
                                        _showOrderSuccessModal(orderData);
                                      }
                                    },
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                isProcessing ? "Processing..." : "Place Order",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= PROCESS CHECKOUT =================
  Future<Map<String, dynamic>?> _processCheckout(
    String userId,
    String deliveryType,
    String paymentMethod,
    String deliveryAddress,
    String deliveryContactNumber,
    String deliveryNotes,
    String customerPhone,
  ) async {
    try {
      print("🔵 Processing checkout...");
      print("   UserId: $userId");
      print("   UserId length: ${userId.length}");
      print("   UserId type: ${userId.runtimeType}");
      print("   Delivery Type: $deliveryType");
      print("   Payment Method: $paymentMethod");

      final body = {
        "userId": userId,
        "deliveryType": deliveryType,
        "paymentMethod": paymentMethod,
        "customerPhone": customerPhone,
      };

      // Add delivery fields if delivery type is delivery
      if (deliveryType == "delivery") {
        body["deliveryAddress"] = deliveryAddress;
        body["deliveryContactNumber"] = deliveryContactNumber;
        body["deliveryNotes"] = deliveryNotes;
      }

      print("   Request body: $body");

      final response = await http.post(
        Uri.parse("http://localhost:5000/api/orders/checkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("   Response status: ${response.statusCode}");
      print("   Response body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("✅ Order placed successfully!");

        // Refresh cart
        fetchCart();
        cartNotifier.value++;

        // Return order data for success modal
        return decoded['order']; // Return order data
      } else {
        print("❌ Order failed with status: ${response.statusCode}");
        print("   Full error response: ${response.body}");

        final decoded = jsonDecode(response.body);
        print("❌ Order failed message: ${decoded['message']}");
        print(
          "   Error details: ${decoded['error'] ?? 'No additional details'}",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${decoded['message'] ?? 'Order failed'}\n\nTip: Try logging out and logging in again.",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            ),
          );
        }

        return null; // Return failure
      }
    } catch (e) {
      print("❌ Error during checkout: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ),
        );
      }

      return null; // Return failure
    }
  }

  double get subtotal {
    double t = 0;
    for (var item in cartItems) {
      final product = item['productId'] ?? {};
      final price = double.tryParse(product['price']?.toString() ?? "0") ?? 0;
      final qty = item['quantity'] ?? 1;
      t += price * qty;
    }
    return t;
  }

  int get totalItems {
    int count = 0;
    for (var item in cartItems) {
      count += (item['quantity'] ?? 0) as int;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        // Delivery Status Banner
        if (!loadingDeliveryStatus && !isDeliveryAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Delivery is currently unavailable. Only pickup orders are accepted.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Cart Items Summary Header
        _buildCartHeader(isMobile),

        // Cart Items List
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 8 : 12,
            ),
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(cartItems[index]);
              },
            ),
          ),
        ),

        // Cart Summary & Checkout
        _buildCartSummary(isMobile),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Add items from the shop to get started",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Shopping Cart",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                Text(
                  "$totalItems ${totalItems == 1 ? 'item' : 'items'}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final product = item['productId'];
    final qty = item['quantity'] ?? 1;
    final name = product['name'] ?? 'Unknown Product';
    final image = product['imageUrl'] ?? "";
    final price = double.tryParse(product['price']?.toString() ?? "0") ?? 0;
    final stock = product['stock'] ?? 0;
    final bool outOfStock = stock == 0;
    final itemTotal = price * qty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outOfStock ? Colors.red[200]! : Colors.grey[200]!,
          width: outOfStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: isMobile ? 70 : 90,
              height: isMobile ? 70 : 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₱${price.toStringAsFixed(2)} each",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 12,
                            color: stock <= 5
                                ? Colors.orange
                                : outOfStock
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Stock: $stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: stock <= 5
                                  ? Colors.orange
                                  : outOfStock
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: stock <= 5 || outOfStock
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: qty > 1 && !outOfStock
                                  ? () =>
                                        updateQuantity(product['_id'], qty - 1)
                                  : null,
                              color: const Color(0xFFFF6F00),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(
                              width: 40,
                              height: 28,
                              child: TextField(
                                key: ValueKey('qty_${product['_id']}_$qty'),
                                controller: TextEditingController.fromValue(
                                  TextEditingValue(
                                    text: qty.toString(),
                                    selection: TextSelection.collapsed(
                                      offset: qty.toString().length,
                                    ),
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                enabled: !outOfStock,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final newQty = int.tryParse(value);
                                  if (newQty != null && newQty > 0) {
                                    if (newQty <= stock) {
                                      updateQuantity(product['_id'], newQty);
                                    } else {
                                      // Clamp to stock limit
                                      updateQuantity(product['_id'], stock);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Only $stock items available",
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  } else if (value.isEmpty) {
                                    // Allow empty for editing, will reset on blur
                                  } else {
                                    // Invalid input, reset to current quantity
                                    updateQuantity(product['_id'], qty);
                                  }
                                },
                                onSubmitted: (value) {
                                  final newQty = int.tryParse(value);
                                  if (newQty == null || newQty < 1) {
                                    // Reset to 1 if invalid
                                    updateQuantity(product['_id'], 1);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Quantity must be at least 1",
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: !outOfStock && qty < stock
                                  ? () =>
                                        updateQuantity(product['_id'], qty + 1)
                                  : null,
                              color: const Color(0xFFFF6F00),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Item Total
                      Text(
                        "₱${itemTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),

                  // Out of Stock Warning
                  if (outOfStock)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Out of Stock",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Quantity Exceeds Stock Warning
                  if (!outOfStock && qty > stock)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Quantity exceeds stock! Only $stock available",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              onPressed: () => _showDeleteConfirmation(product['_id'], name),
              tooltip: 'Remove item',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(bool isMobile) {
    final bool hasOutOfStock = cartItems.any(
      (item) => (item['productId']['stock'] ?? 0) == 0,
    );
    final bool hasExceededStock = cartItems.any((item) {
      final stock = item['productId']['stock'] ?? 0;
      final qty = item['quantity'] ?? 0;
      return qty > stock;
    });
    final tax = subtotal * 0.0; // Add tax if needed
    final shipping = 0.0; // Add shipping if needed
    final total = subtotal + tax + shipping;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              isMobile ? 8 : 12,
              isMobile ? 12 : 16,
              isMobile ? 6 : 8,
            ),
            child: Column(
              children: [
                // Subtotal
                _buildSummaryRow("Subtotal", subtotal, false),
                if (tax > 0) ...[
                  const SizedBox(height: 4),
                  _buildSummaryRow("Tax", tax, false),
                ],
                if (shipping > 0) ...[
                  const SizedBox(height: 4),
                  _buildSummaryRow("Shipping", shipping, false),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(thickness: 1),
                ),
                // Total
                _buildSummaryRow("Total", total, true),
              ],
            ),
          ),

          // Warning for out of stock
          if (hasOutOfStock)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Remove out-of-stock items to proceed",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Warning for exceeded stock
          if (!hasOutOfStock && hasExceededStock)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Some items exceed available stock. Please adjust quantities.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Checkout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: hasOutOfStock || hasExceededStock ? null : checkout,
                icon: const Icon(Icons.shopping_bag, size: 18),
                label: const Text(
                  "Proceed to Checkout",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF212121) : Colors.grey[700],
          ),
        ),
        Text(
          "₱${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF4CAF50) : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // ================= DELIVERY OPTION BUILDER =================
  Widget _buildDeliveryOption(
    BuildContext context,
    StateSetter setDialogState,
    String currentType,
    String value,
    String title,
    IconData icon,
    String subtitle,
    bool isProcessing,
    Function(String) onChanged,
  ) {
    final isSelected = currentType == value;
    final isDisabled =
        isProcessing || (value == "delivery" && !isDeliveryAvailable);

    return InkWell(
      onTap: isDisabled ? null : () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : isSelected
              ? const Color(0xFFFFC107).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[400]!
                : isSelected
                ? const Color(0xFFFFC107)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? Colors.grey[500]
                  : isSelected
                  ? const Color(0xFFFF6F00)
                  : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDisabled
                    ? Colors.grey[500]
                    : isSelected
                    ? const Color(0xFFFF6F00)
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDisabled ? Colors.grey[500] : Colors.grey[600],
                fontWeight: subtitle == "Unavailable"
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= PAYMENT OPTION BUILDER =================
  Widget _buildPaymentOption(
    BuildContext context,
    StateSetter setDialogState,
    String currentMethod,
    String value,
    String title,
    IconData icon,
    Color color,
    bool isProcessing,
    Function(String) onChanged,
  ) {
    final isSelected = currentMethod == value;
    return InkWell(
      onTap: isProcessing ? null : () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ORDER SUCCESS MODAL =================
  void _showOrderSuccessModal(dynamic order) async {
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final deliveryType = order['deliveryType'] ?? 'pickup';
    final paymentMethod = order['paymentMethod'] ?? '';

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
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  color: Colors.white,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Order Placed Successfully!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (orderId.isNotEmpty)
                          Text(
                            "Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    deliveryType == "pickup"
                                        ? Icons.store
                                        : Icons.delivery_dining,
                                    color: const Color(0xFFFF6F00),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    deliveryType == "pickup"
                                        ? "Pick-up Order"
                                        : "Delivery Order",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    paymentMethod == "gcash"
                                        ? Icons.account_balance_wallet
                                        : Icons.payments,
                                    color: paymentMethod == "gcash"
                                        ? Colors.blue
                                        : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    paymentMethod == "gcash" ? "GCash" : "Cash",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          deliveryType == "pickup"
                              ? "We'll notify you when your order is ready!"
                              : "We'll notify you when your order is out for delivery!",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Auto-dismiss after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showDeleteConfirmation(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text("Remove Item?"),
          ],
        ),
        content: Text("Remove '$productName' from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              removeItem(productId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
