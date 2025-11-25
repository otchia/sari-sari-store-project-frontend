import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../globals.dart';
import './product_detail.dart'; // <-- Import the real ProductDetail

class CustomerShopFixed extends StatefulWidget {
  final String searchQuery;
  final String? selectedCategory;

  const CustomerShopFixed({
    super.key,
    this.searchQuery = '',
    this.selectedCategory,
  });

  @override
  State<CustomerShopFixed> createState() => _CustomerShopFixedState();
}

class _CustomerShopFixedState extends State<CustomerShopFixed> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool loading = true;
  Map<String, int> quantities = {};
  Map<String, TextEditingController> qtyControllers = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    for (var c in qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/products'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetched =
            (decoded is Map && decoded['products'] is List)
            ? List<dynamic>.from(decoded['products'])
            : (decoded is List ? List<dynamic>.from(decoded) : []);
        setState(() {
          products = fetched;
          loading = false;
          quantities.clear();
          qtyControllers.clear();
          for (var p in products) {
            final id = (p?['_id'] ?? '').toString();
            if (id.isNotEmpty) {
              quantities[id] = 1;
              qtyControllers[id] = TextEditingController(text: '1');
            }
          }
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch products: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching products: $e')));
    }
  }

  int _parseAndClampQty(String productId, int stock) {
    final controller = qtyControllers[productId];
    if (controller == null) return 1;
    final raw = controller.text.trim();
    final parsed = int.tryParse(raw) ?? quantities[productId] ?? 1;
    final clamped = parsed.clamp(1, stock);
    controller.text = clamped.toString();
    quantities[productId] = clamped;
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

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 1024) return 3;
    return 4;
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

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    filteredProducts = products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      final matchesSearch = name.contains(query);
      final category = (product['category'] ?? '').toString();
      final matchesCategory =
          (widget.selectedCategory == null || widget.selectedCategory == 'All')
          ? true
          : category == widget.selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredProducts.isEmpty) {
      return _buildNoResultsState();
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(width);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filteredProducts[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            "No products available",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new items",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 80,
              color: Color(0xFFFFC107),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No products found",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic productData) {
    final Map<String, dynamic> product = Map<String, dynamic>.from(productData);
    final productId = (product['_id'] ?? '').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final name = (product['name'] ?? 'Unnamed Product').toString();
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final qty = quantities[productId] ?? 1;
    final outOfStock = stock <= 0;
    final lowStock = stock > 0 && stock <= 5;

    qtyControllers.putIfAbsent(
      productId,
      () => TextEditingController(text: qty.toString()),
    );

    return GestureDetector(
      onTap: () => ProductDetailModal.show(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: outOfStock ? Colors.red[200]! : Colors.grey[200]!,
            width: outOfStock ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.inventory_2,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                // Out of Stock Badge
                if (outOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Low Stock Badge
                if (lowStock && !outOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'Only $stock left',
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

            // Product Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price & Stock in one row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₱${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 12,
                            color: lowStock
                                ? Colors.orange
                                : outOfStock
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: lowStock
                                  ? Colors.orange
                                  : outOfStock
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: lowStock || outOfStock
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Quantity Controls
                  if (!outOfStock) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: qty <= 1
                                    ? null
                                    : () {
                                        setState(() {
                                          quantities[productId] = qty - 1;
                                          qtyControllers[productId]?.text =
                                              (qty - 1).toString();
                                        });
                                      },
                                icon: const Icon(Icons.remove, size: 16),
                                color: const Color(0xFFFF6F00),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(
                                width: 35,
                                height: 24,
                                child: TextField(
                                  controller: qtyControllers[productId],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {
                                    _parseAndClampQty(productId, stock);
                                  }),
                                ),
                              ),
                              IconButton(
                                onPressed: qty >= stock
                                    ? null
                                    : () {
                                        setState(() {
                                          quantities[productId] = qty + 1;
                                          qtyControllers[productId]?.text =
                                              (qty + 1).toString();
                                        });
                                      },
                                icon: const Icon(Icons.add, size: 16),
                                color: const Color(0xFFFF6F00),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: outOfStock
                          ? null
                          : () {
                              addToCart(
                                productId,
                                _parseAndClampQty(productId, stock),
                              );
                            },
                      icon: Icon(
                        outOfStock
                            ? Icons.remove_shopping_cart
                            : Icons.add_shopping_cart,
                        size: 16,
                      ),
                      label: Text(
                        outOfStock ? 'Out of Stock' : 'Add to Cart',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: outOfStock
                            ? Colors.grey[300]
                            : const Color(0xFFFFC107),
                        foregroundColor: outOfStock
                            ? Colors.grey[700]
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: outOfStock ? 0 : 2,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
