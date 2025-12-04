import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../globals.dart';

class ProductDetailModal {
  static void show(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: ProductDetail(product: product),
        ),
      ),
    );
  }
}

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
        Navigator.of(context).pop(); // Close modal after adding to cart
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
    final name = product['name'] ?? 'Product';
    final description = product['description'] ?? 'No description provided.';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.black54),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 10 : 24),
                    child: isWide
                        ? _buildWideLayout(
                            imageUrl,
                            price,
                            stock,
                            name,
                            description,
                          )
                        : _buildNarrowLayout(
                            imageUrl,
                            price,
                            stock,
                            name,
                            description,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    String imageUrl,
    double price,
    int stock,
    String name,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section (left side)
        Expanded(flex: 5, child: _buildImageSection(imageUrl)),
        const SizedBox(width: 32),
        // Details section (right side)
        Expanded(
          flex: 5,
          child: _buildDetailsSection(price, stock, description),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    String imageUrl,
    double price,
    int stock,
    String name,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(imageUrl),
        const SizedBox(height: 24),
        _buildDetailsSection(price, stock, description),
      ],
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(double price, int stock, String description) {
    final product = widget.product;
    final outOfStock = stock <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            '₱${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Product info cards
        _buildInfoCard([
          _buildInfoItem(Icons.local_offer, 'Brand', product['brand']),
          _buildInfoItem(Icons.category, 'Category', product['category']),
          _buildInfoItem(Icons.style, 'Variation', product['variation']),
          _buildInfoItem(
            Icons.calendar_today,
            'Shelf Life',
            product['shelfLife'],
          ),
        ]),
        const SizedBox(height: 20),
        // Stock status
        _buildStockBadge(stock, outOfStock),
        const SizedBox(height: 20),
        // Description
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 24),
        // Quantity selector
        _buildQuantitySelector(stock, outOfStock),
        const SizedBox(height: 20),
        // Add to cart button
        _buildAddToCartButton(stock, outOfStock),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool outOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: outOfStock ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: outOfStock ? Colors.red[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            outOfStock ? Icons.remove_shopping_cart : Icons.inventory_2,
            size: 20,
            color: outOfStock ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            outOfStock ? 'Out of Stock' : 'Stock: $stock',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: outOfStock ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(int stock, bool outOfStock) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'Quantity:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
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
                IconButton(
                  onPressed: outOfStock || quantity <= 1
                      ? null
                      : () {
                          setState(() {
                            quantity--;
                            qtyController.text = quantity.toString();
                          });
                        },
                  icon: const Icon(Icons.remove, size: 20),
                  color: Colors.orangeAccent,
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: qtyController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !outOfStock,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {
                      _parseAndClampQty(stock);
                    }),
                  ),
                ),
                IconButton(
                  onPressed: outOfStock || quantity >= stock
                      ? null
                      : () {
                          setState(() {
                            quantity++;
                            qtyController.text = quantity.toString();
                          });
                        },
                  icon: const Icon(Icons.add, size: 20),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(int stock, bool outOfStock) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: outOfStock
            ? null
            : () => addToCart(widget.product['_id'] ?? '', quantity),
        icon: const Icon(Icons.shopping_cart, size: 22),
        label: Text(
          outOfStock ? 'Out of Stock' : 'Add to Cart',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
