import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerShop extends StatefulWidget {
  final String searchQuery; // 🔍 Search input from navbar
  final String? selectedCategory; // 🏷️ Category filter

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
  List<dynamic> filteredProducts = []; // 🔹 Filtered products list
  bool loading = true;

  // Each product will have its own quantity
  Map<int, int> quantities = {};

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

          // Initialize quantities (default = 1)
          for (int i = 0; i < products.length; i++) {
            quantities[i] = 1;
          }
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch products: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching products: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const Center(child: Text("No products available"));
    }

    // 🔹 Apply search + category filter
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

          final imageUrl = (product['imageUrl'] as String?) ??
              (product['image'] as String?) ??
              '';

          double price = 0.0;
          if (product['price'] != null) {
            price = double.tryParse(product['price'].toString()) ?? 0.0;
          }

          final name = product['name'] ?? 'Unnamed product';
          final category = product['category'] ?? '';
          final stock = product['stock']?.toString() ?? '0';

          int qty = quantities[index] ?? 1;

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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 40),
                              );
                            },
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
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₱${price.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          Text(
                            "Stock: $stock",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 🔥 Quantity selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: qty > 1
                                ? () {
                                    setState(() {
                                      quantities[index] = qty - 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            qty.toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantities[index] = qty + 1;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Added $qty × $name to cart (coming soon)"),
                              ),
                            );
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
