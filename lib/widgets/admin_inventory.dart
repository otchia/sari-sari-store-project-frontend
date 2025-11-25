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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading products: $e")));
    }
  }

  void sortProducts() {
    setState(() {
      if (sortBy == 'Alphabetical') {
        products.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortBy == 'Category') {
        products.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (sortBy == 'Date Added') {
        products.sort(
          (a, b) => DateTime.parse(
            b['createdAt'],
          ).compareTo(DateTime.parse(a['createdAt'])),
        );
      }
    });
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse("http://localhost:5000/api/products/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() => products.removeWhere((p) => p['_id'] == id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Product deleted")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete error: $e")));
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
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:5000/api/products/upload-image'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: file.name,
            contentType: http.MediaType('image', file.name.split('.').last),
          ),
        );

        final response = await request.send();
        if (response.statusCode == 200) {
          final resBody = await response.stream.bytesToString();
          final decoded = jsonDecode(resBody);
          setState(() {
            pickedImageUrl = decoded['imageUrl'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.statusCode}')),
          );
        }
      });
    });
  }

  void showAddEditDialog({Map? product}) {
    final name = TextEditingController(text: product?['name'] ?? '');
    final category = TextEditingController(text: product?['category'] ?? '');
    final price = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final stock = TextEditingController(
      text: product?['stock']?.toString() ?? '',
    );
    final brand = TextEditingController(text: product?['brand'] ?? '');
    final variation = TextEditingController(text: product?['variation'] ?? '');
    final description = TextEditingController(
      text: product?['description'] ?? '',
    );
    final weight = TextEditingController(
      text: product?['weight']?.toString() ?? '',
    );
    final shelfLife = TextEditingController(text: product?['shelfLife'] ?? '');

    pickedImageUrl = product?['imageUrl'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          product != null
                              ? Icons.edit_rounded
                              : Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        product != null ? "Edit Product" : "Add New Product",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          "Basic Information",
                          Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          name,
                          "Product Name",
                          Icons.shopping_bag_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                brand,
                                "Brand",
                                Icons.business_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                category,
                                "Category",
                                Icons.category_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          variation,
                          "Variation",
                          Icons.tune_outlined,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          "Pricing & Stock",
                          Icons.attach_money_rounded,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                price,
                                "Price",
                                Icons.currency_exchange_outlined,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                stock,
                                "Stock Quantity",
                                Icons.inventory_outlined,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          "Description",
                          Icons.description_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          description,
                          "Product Description",
                          Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          "Additional Details",
                          Icons.more_horiz_rounded,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                weight,
                                "Weight (grams)",
                                Icons.scale_outlined,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                shelfLife,
                                "Shelf Life (YYYY-MM-DD)",
                                Icons.calendar_today_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          "Product Image",
                          Icons.image_outlined,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              if (pickedImageUrl != null &&
                                  pickedImageUrl!.isNotEmpty)
                                Container(
                                  width: 200,
                                  height: 200,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      pickedImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await pickAndUploadImage();
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.upload_rounded),
                                label: Text(
                                  pickedImageUrl != null &&
                                          pickedImageUrl!.isNotEmpty
                                      ? "Change Image"
                                      : "Upload Image",
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD32F2F),
                                  side: const BorderSide(
                                    color: Color(0xFFD32F2F),
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          "Save Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final data = {
                            'name': name.text,
                            'category': category.text,
                            'price': double.tryParse(price.text) ?? 0,
                            'stock': int.tryParse(stock.text) ?? 0,
                            'imageUrl': pickedImageUrl ?? '',
                            'brand': brand.text,
                            'variation': variation.text,
                            'description': description.text,
                            'weight': double.tryParse(weight.text) ?? 0,
                            'shelfLife': shelfLife.text,
                          };

                          if (product != null) {
                            final url = Uri.parse(
                              "http://localhost:5000/api/products/${product['_id']}",
                            );
                            await http.put(
                              url,
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode(data),
                            );
                          } else {
                            final url = Uri.parse(
                              "http://localhost:5000/api/products/add",
                            );
                            await http.post(
                              url,
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode(data),
                            );
                          }

                          Navigator.pop(context);
                          fetchProducts();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD32F2F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFD32F2F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with controls
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD32F2F).withOpacity(0.1),
                const Color(0xFFB71C1C).withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Product Inventory",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        "${products.length} items",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: sortBy,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'Alphabetical',
                              child: Text("Alphabetical"),
                            ),
                            DropdownMenuItem(
                              value: 'Category',
                              child: Text("Category"),
                            ),
                            DropdownMenuItem(
                              value: 'Date Added',
                              child: Text("Date Added"),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => sortBy = v);
                              sortProducts();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      "Add Product",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => showAddEditDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Product Grid
        Expanded(
          child: products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return _buildProductCard(p);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No products yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first product to get started",
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Product"),
            onPressed: () => showAddEditDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map p) {
    final stock = p['stock'] ?? 0;
    final isLowStock = stock > 0 && stock <= 10;
    final isOutOfStock = stock == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? Colors.red.shade200
              : isLowStock
              ? Colors.orange.shade200
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: p['imageUrl'] != null && p['imageUrl'] != ''
                        ? Image.network(
                            p['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(
                            Icons.inventory_2_rounded,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                ),
                if (isOutOfStock || isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: (isOutOfStock ? Colors.red : Colors.orange)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isOutOfStock ? "Out of Stock" : "Low Stock",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['category'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₱${p['price'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          Text(
                            "Stock: ${p['stock']}",
                            style: TextStyle(
                              fontSize: 11,
                              color: isOutOfStock
                                  ? Colors.red
                                  : isLowStock
                                  ? Colors.orange
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            color: Colors.blue,
                            onPressed: () => showAddEditDialog(product: p),
                            tooltip: "Edit",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, size: 20),
                            color: Colors.red,
                            onPressed: () => _confirmDelete(p['_id']),
                            tooltip: "Delete",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text("Confirm Delete"),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this product? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
