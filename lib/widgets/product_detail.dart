import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../globals.dart';

class ProductDetail extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetail({super.key, required this.product});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late TextEditingController qtyController;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  int _parseAndClampQty(int stock) {
    final raw = qtyController.text.trim();
    final parsed = int.tryParse(raw) ?? quantity;
    final clamped = parsed.clamp(1, stock);
    qtyController.text = clamped.toString();
    quantity = clamped;
    return clamped;
  }

  Future<void> addToCart(String productId, int qty) async {
    final String? userId = html.window.localStorage['customerId'];
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in!')));
      return;
    }
    final url = Uri.parse('http://localhost:5000/api/cart/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'quantity': qty,
        }),
      );
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        decoded = null;
      }
      if (response.statusCode == 200 && decoded != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added $qty item(s) to cart')));
        cartNotifier.value++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded != null
                  ? (decoded['message'] ?? 'Failed to add to cart')
                  : 'Server error',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = double.tryParse(product['price'].toString()) ?? 0;
    final stock = int.tryParse(product['stock'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 80),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '₱${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Brand', product['brand']),
            _buildInfoRow('Category', product['category']),
            _buildInfoRow('Variation', product['variation']),
            _buildInfoRow('Shelf Life', product['shelfLife']),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              product['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 1
                      ? () {
                          setState(() {
                            quantity--;
                            qtyController.text = quantity.toString();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: qtyController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {
                      _parseAndClampQty(stock);
                    }),
                  ),
                ),
                IconButton(
                  onPressed: quantity < stock
                      ? () {
                          setState(() {
                            quantity++;
                            qtyController.text = quantity.toString();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 16),
                Text('Stock: $stock'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: stock <= 0
                    ? null
                    : () => addToCart(product['_id'] ?? '', quantity),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  stock <= 0 ? 'Out of Stock' : 'Add to Cart',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title: ${value ?? 'N/A'}',
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}
