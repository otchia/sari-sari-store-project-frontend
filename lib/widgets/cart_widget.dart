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
    if (userId == null) {
      setState(() {
        cartItems = [];
        loading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("http://localhost:5000/api/cart/$userId"),
      );

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
    if (userId == null) return;

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/api/cart/checkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (res.statusCode == 200) {
        fetchCart();
        cartNotifier.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Checkout successful! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final decoded = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Checkout failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error during checkout"),
          backgroundColor: Colors.red,
        ),
      );
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
