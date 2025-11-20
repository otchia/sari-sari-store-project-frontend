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
      final res =
          await http.get(Uri.parse("http://localhost:5000/api/cart/$userId"));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final items = decoded is Map
            ? decoded['items'] ?? []
            : (decoded is List ? decoded : []);

        setState(() {
          cartItems = items;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> removeItem(String productId) async {
    final userId = html.window.localStorage['customerId'];
    if (userId == null) return;

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/api/cart/delete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "productId": productId}),
      );

      if (res.statusCode == 200) {
        fetchCart();
        cartNotifier.value++;
      }
    } catch (_) {}
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final userId = html.window.localStorage['customerId'];
    if (userId == null) return;

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/api/cart/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"userId": userId, "productId": productId, "quantity": quantity}),
      );

      if (res.statusCode == 200) {
        fetchCart();
        cartNotifier.value++;
      }
    } catch (_) {}
  }

  double get total {
    double t = 0;
    for (var item in cartItems) {
      final p = item['productId'] ?? {};
      final price = double.tryParse(p['price']?.toString() ?? "0") ?? 0;
      final qty = item['quantity'] ?? 1;
      t += price * qty;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty"))
              : Column(
                  children: [
                    const Text("Your Cart",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final product = item['productId'];
                          final qty = item['quantity'];
                          final name = product['name'];
                          final image = product['imageUrl'] ?? "";
                          final price = double.tryParse(
                                  product['price']?.toString() ?? "0") ??
                              0;

                          return Card(
                            child: ListTile(
                              leading: image.isNotEmpty
                                  ? Image.network(image,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.inventory_2),
                              title: Text(name),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("₱${price.toStringAsFixed(2)} × $qty"),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: qty > 1
                                            ? () => updateQuantity(
                                                product['_id'], qty - 1)
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: () => updateQuantity(
                                            product['_id'], qty + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeItem(product['_id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total: ₱${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("Checkout"))
                      ],
                    ),
                  ],
                ),
    );
  }
}
