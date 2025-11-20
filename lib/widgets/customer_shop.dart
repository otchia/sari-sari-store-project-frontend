import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // ⭐ Needed for localStorage (Web)
import '../globals.dart'; // 🔹 Import the cartNotifier

class CustomerShop extends StatefulWidget {
  final String searchQuery;
  final String? selectedCategory;

  const CustomerShop({
    super.key,
    required this.searchQuery,
    this.selectedCategory,
  });

  @override
  State<CustomerShop> createState() => _CustomerShopState();
}

class _CustomerShopState extends State<CustomerShop> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool loading = true;

  Map<String, int> quantities = {}; // key = productId

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    try {
      final response =
          await http.get(Uri.parse("http://localhost:5000/api/products"));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> fetched =
            (decoded is Map && decoded['products'] is List)
                ? List<dynamic>.from(decoded['products'])
                : (decoded is List ? List<dynamic>.from(decoded) : []);

        setState(() {
          products = fetched;
          loading = false;

          // Default quantities = 1 for each product by _id
          for (var product in products) {
            final productId = product['_id'] ?? '';
            if (productId.isNotEmpty) quantities[productId] = 1;
          }
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to fetch products: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching products: $e")),
      );
    }
  }

  // ⭐ ADD TO CART FUNCTION
  Future<void> addToCart(String productId, int qty) async {
    final String? userId = html.window.localStorage['customerId'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in!")),
      );
      return;
    }

    final url = Uri.parse("http://localhost:5000/api/cart/add");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "productId": productId,
          "quantity": qty,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Added $qty item(s) to cart")),
        );

        // 🔹 Update the global cart notifier
        cartNotifier.value++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to add to cart: ${response.statusCode} — ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding to cart: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty)
      return const Center(child: Text("No products available"));

    filteredProducts = products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final query = widget.searchQuery.toLowerCase();

      final matchesSearch = name.contains(query);

      final category = product['category']?.toString() ?? '';
      final matchesCategory =
          (widget.selectedCategory == null || widget.selectedCategory == "All")
              ? true
              : category == widget.selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index] as Map<String, dynamic>;
          final productId = product['_id'] ?? '';
          final imageUrl = product['imageUrl'] ?? '';
          final name = product['name'] ?? 'Unnamed Product';
          final category = product['category'] ?? '';
          final stock = product['stock']?.toString() ?? '0';
          final price = double.tryParse(product['price'].toString()) ?? 0.0;
          final qty = quantities[productId] ?? 1;

          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(Icons.inventory_2, size: 48),
                          ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(category,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("₱${price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Text("Stock: $stock",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // ⭐ Quantity Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: qty > 1
                                ? () {
                                    setState(() {
                                      quantities[productId] = qty - 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(qty.toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantities[productId] = qty + 1;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ⭐ ADD TO CART BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            addToCart(productId, qty);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text("Add to Cart"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
