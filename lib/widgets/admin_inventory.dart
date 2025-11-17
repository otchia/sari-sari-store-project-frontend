import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key});

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  List products = [];
  String sortBy = 'Date Added'; // Default sort

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // Fetch products from backend
  Future<void> fetchProducts() async {
    final url = Uri.parse("http://localhost:5000/api/products");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          products = decoded['products'];
          sortProducts();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching products: $e")),
      );
    }
  }

  // Sorting
  void sortProducts() {
    setState(() {
      if (sortBy == 'Alphabetical') {
        products.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()));
      } else if (sortBy == 'Category') {
        products.sort((a, b) =>
            a['category'].toString().compareTo(b['category'].toString()));
      } else if (sortBy == 'Date Added') {
        products.sort((a, b) => DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));
      }
    });
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    final url = Uri.parse("http://localhost:5000/api/products/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          products.removeWhere((p) => p['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting product: $e")),
      );
    }
  }

  // Add/Edit Dialog
  void showAddEditDialog({Map? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final categoryController =
        TextEditingController(text: product?['category'] ?? '');
    final priceController = TextEditingController(
        text: product != null ? product['price'].toString() : '');
    final stockController = TextEditingController(
        text: product != null ? product['stock'].toString() : '');
    final imageController =
        TextEditingController(text: product?['imageUrl'] ?? '');
    final brandController =
        TextEditingController(text: product?['brand'] ?? '');
    final variationController =
        TextEditingController(text: product?['variation'] ?? '');
    final descriptionController =
        TextEditingController(text: product?['description'] ?? '');
    final weightController = TextEditingController(
        text: product != null ? product['weight'].toString() : '');
    final shelfLifeController =
        TextEditingController(text: product?['shelfLife'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product != null ? "Edit Product" : "Add Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL')),
              TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Brand')),
              TextField(
                  controller: variationController,
                  decoration: const InputDecoration(labelText: 'Variation')),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                  controller: weightController,
                  decoration:
                      const InputDecoration(labelText: 'Weight (grams)'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: shelfLifeController,
                  decoration: const InputDecoration(
                      labelText: 'Shelf Life (YYYY-MM-DD)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'category': categoryController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'imageUrl': imageController.text,
                'brand': brandController.text,
                'variation': variationController.text,
                'description': descriptionController.text,
                'weight': double.tryParse(weightController.text) ?? 0,
                'shelfLife': shelfLifeController.text.isNotEmpty
                    ? shelfLifeController.text
                    : null,
              };

              if (product != null) {
                // EDIT
                final url = Uri.parse(
                    "http://localhost:5000/api/products/${product['_id']}");
                await http.put(url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(data));
              } else {
                // ADD
                final url = Uri.parse("http://localhost:5000/api/products/add");
                await http.post(url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(data));
              }

              Navigator.pop(context);
              fetchProducts(); // Refresh list
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header & Sort Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Inventory",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  DropdownButton<String>(
                    value: sortBy,
                    items: const [
                      DropdownMenuItem(
                          value: 'Alphabetical', child: Text('Alphabetical')),
                      DropdownMenuItem(
                          value: 'Category', child: Text('Category')),
                      DropdownMenuItem(
                          value: 'Date Added', child: Text('Date Added')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        sortBy = value;
                        sortProducts();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Product"),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Product List
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text("No products yet"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: product['imageUrl'] != null &&
                                product['imageUrl'] != ''
                            ? Image.network(product['imageUrl'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.inventory_2,
                                size: 50, color: Colors.grey),
                        title: Text(product['name']),
                        subtitle: Text(
                            "${product['category']} • \$${product['price']} • Stock: ${product['stock']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  showAddEditDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProduct(product['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
