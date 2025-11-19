import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key});

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  List products = [];
  String sortBy = 'Date Added';
  String? pickedImageUrl; // stores uploaded image URL

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ---------------- FETCH, SORT, DELETE (same as your code) ----------------
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
        SnackBar(content: Text("Error loading products: $e")),
      );
    }
  }

  void sortProducts() {
    setState(() {
      if (sortBy == 'Alphabetical') {
        products.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortBy == 'Category') {
        products.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (sortBy == 'Date Added') {
        products.sort((a, b) => DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));
      }
    });
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse("http://localhost:5000/api/products/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() => products.removeWhere((p) => p['_id'] == id));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Product deleted")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Delete error: $e")));
    }
  }

  // ---------------- PICK & UPLOAD IMAGE ----------------
  Future<void> pickAndUploadImage() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // only images
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result as List<int>;
        final request = http.MultipartRequest('POST',
            Uri.parse('http://localhost:5000/api/products/upload-image'));
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: file.name,
          contentType: http.MediaType('image', file.name.split('.').last),
        ));

        final response = await request.send();
        if (response.statusCode == 200) {
          final resBody = await response.stream.bytesToString();
          final decoded = jsonDecode(resBody);
          setState(() {
            pickedImageUrl = decoded['imageUrl'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${response.statusCode}')));
        }
      });
    });
  }

  // ---------------- ADD / EDIT PRODUCT DIALOG ----------------
  void showAddEditDialog({Map? product}) {
    final name = TextEditingController(text: product?['name'] ?? '');
    final category = TextEditingController(text: product?['category'] ?? '');
    final price =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final stock =
        TextEditingController(text: product?['stock']?.toString() ?? '');
    final brand = TextEditingController(text: product?['brand'] ?? '');
    final variation = TextEditingController(text: product?['variation'] ?? '');
    final description =
        TextEditingController(text: product?['description'] ?? '');
    final weight =
        TextEditingController(text: product?['weight']?.toString() ?? '');
    final shelfLife = TextEditingController(text: product?['shelfLife'] ?? '');

    // If editing an existing product, prefill image
    pickedImageUrl = product?['imageUrl'] ?? null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product != null ? "Edit Product" : "Add Product"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Basic Info ---
              const Text("Basic Information",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Product Name")),
              TextField(
                  controller: brand,
                  decoration: const InputDecoration(labelText: "Brand")),
              TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: "Category")),
              TextField(
                  controller: variation,
                  decoration: const InputDecoration(labelText: "Variation")),
              const SizedBox(height: 16),

              // --- Pricing & Stock ---
              const Text("Pricing & Stock",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price")),
              TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Stock")),
              const SizedBox(height: 16),

              // --- Description ---
              const Text("Description",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 16),

              // --- Extra Details ---
              const Text("Additional Details",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Weight (grams)")),
              TextField(
                  controller: shelfLife,
                  decoration: const InputDecoration(
                      labelText: "Shelf Life (YYYY-MM-DD)")),
              const SizedBox(height: 16),

              // --- Image Picker & Preview ---
              const Text("Product Image",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: pickAndUploadImage,
                child: const Text("Pick Image"),
              ),
              const SizedBox(height: 8),
              pickedImageUrl != null
                  ? Image.network(pickedImageUrl!,
                      width: 100, height: 100, fit: BoxFit.cover)
                  : Container(),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              final data = {
                'name': name.text,
                'category': category.text,
                'price': double.tryParse(price.text) ?? 0,
                'stock': int.tryParse(stock.text) ?? 0,
                'imageUrl': pickedImageUrl ?? '', // use uploaded image URL
                'brand': brand.text,
                'variation': variation.text,
                'description': description.text,
                'weight': double.tryParse(weight.text) ?? 0,
                'shelfLife': shelfLife.text,
              };

              if (product != null) {
                // UPDATE
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
              fetchProducts();
            },
          ),
        ],
      ),
    );
  }

  // ---------------- UI (same as your original) ----------------
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header and Add button
        Padding(
          padding: const EdgeInsets.all(16),
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
                          value: 'Alphabetical', child: Text("Alphabetical")),
                      DropdownMenuItem(
                          value: 'Category', child: Text("Category")),
                      DropdownMenuItem(
                          value: 'Date Added', child: Text("Date Added")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => sortBy = v);
                        sortProducts();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Product"),
                    onPressed: () => showAddEditDialog(),
                  )
                ],
              ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text("No products yet"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: p['imageUrl'] != null && p['imageUrl'] != ''
                            ? Image.network(p['imageUrl'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.inventory_2,
                                size: 50, color: Colors.grey),
                        title: Text(p['name']),
                        subtitle: Text(
                            "${p['category']} • ₱${p['price']} • Stock: ${p['stock']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => showAddEditDialog(product: p)),
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteProduct(p['_id'])),
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
