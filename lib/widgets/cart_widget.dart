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

  @override
  void initState() {
    super.initState();
    fetchCart();

    cartNotifier.addListener(() {
      fetchCart();
    });
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
    String deliveryType = "pickup"; // Default to pickup (AC1)
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
                          IconButton(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
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
                              "Deliver to address",
                              isProcessing,
                              (value) {
                                setDialogState(() => deliveryType = value);
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
                                      await _processCheckout(
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

                                      if (mounted) {
                                        Navigator.pop(context);
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
  Future<void> _processCheckout(
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

        // Show success modal
        if (mounted) {
          _showOrderSuccessModal(decoded['order']);
        }
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
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error during checkout: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
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
        // Cart Items Summary Header
        _buildCartHeader(),

        // Cart Items List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(cartItems[index]);
              },
            ),
          ),
        ),

        // Cart Summary & Checkout
        _buildCartSummary(),
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

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Shopping Cart",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                Text(
                  "$totalItems ${totalItems == 1 ? 'item' : 'items'}",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: outOfStock ? Colors.red[200]! : Colors.grey[200]!,
          width: outOfStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(width: 20),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₱${price.toStringAsFixed(2)} each",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  // Quantity Controls
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: qty > 1 && !outOfStock
                                  ? () =>
                                        updateQuantity(product['_id'], qty - 1)
                                  : null,
                              color: const Color(0xFFFF6F00),
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                qty.toString(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: !outOfStock && qty < stock
                                  ? () =>
                                        updateQuantity(product['_id'], qty + 1)
                                  : null,
                              color: const Color(0xFFFF6F00),
                              padding: const EdgeInsets.all(10),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),

                  // Out of Stock Warning
                  if (outOfStock)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Out of Stock",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
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
              icon: const Icon(Icons.delete_outline, size: 24),
              color: Colors.red[400],
              onPressed: () => _showDeleteConfirmation(product['_id'], name),
              tooltip: 'Remove item',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    final bool hasOutOfStock = cartItems.any(
      (item) => (item['productId']['stock'] ?? 0) == 0,
    );
    final tax = subtotal * 0.0; // Add tax if needed
    final shipping = 0.0; // Add shipping if needed
    final total = subtotal + tax + shipping;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                // Subtotal
                _buildSummaryRow("Subtotal", subtotal, false),
                if (tax > 0) ...[
                  const SizedBox(height: 6),
                  _buildSummaryRow("Tax", tax, false),
                ],
                if (shipping > 0) ...[
                  const SizedBox(height: 6),
                  _buildSummaryRow("Shipping", shipping, false),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
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
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Remove out-of-stock items to proceed",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Checkout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: hasOutOfStock ? null : checkout,
                icon: const Icon(Icons.shopping_bag, size: 20),
                label: const Text(
                  "Proceed to Checkout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF212121) : Colors.grey[700],
          ),
        ),
        Text(
          "₱${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
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
    return InkWell(
      onTap: isProcessing ? null : () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFC107).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC107) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6F00) : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFF6F00) : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  void _showOrderSuccessModal(dynamic order) {
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
              child: Card(
                color: Colors.white,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Order Placed Successfully!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (orderId.isNotEmpty)
                        Text(
                          "Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
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
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  deliveryType == "pickup"
                                      ? "Pick-up Order"
                                      : "Delivery Order",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paymentMethod == "gcash" ? "GCash" : "Cash",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        deliveryType == "pickup"
                            ? "We'll notify you when your order is ready!"
                            : "We'll notify you when your order is out for delivery!",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "View Orders",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
