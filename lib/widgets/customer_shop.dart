import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../globals.dart';

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
    if (loading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty)
      return const Center(child: Text('No products available'));

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

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(width);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> product = Map<String, dynamic>.from(
                filteredProducts[index],
              );
              final productId = (product['_id'] ?? '').toString();
              final imageUrl = (product['imageUrl'] ?? '').toString();
              final name = (product['name'] ?? 'Unnamed Product').toString();
              final stock =
                  int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
              final price =
                  double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
              final qty = quantities[productId] ?? 1;
              final outOfStock = stock <= 0;
              qtyControllers.putIfAbsent(
                productId,
                () => TextEditingController(text: qty.toString()),
              );

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetail(product: product),
                  ),
                ),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1 / 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.inventory_2,
                                    size: 48,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: $stock',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: outOfStock || qty <= 1
                                        ? null
                                        : () {
                                            setState(() {
                                              quantities[productId] = qty - 1;
                                              qtyControllers[productId]?.text =
                                                  (qty - 1).toString();
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    height: 36,
                                    child: TextField(
                                      controller: qtyControllers[productId],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {
                                        _parseAndClampQty(productId, stock);
                                      }),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: outOfStock || qty >= stock
                                        ? null
                                        : () {
                                            setState(() {
                                              quantities[productId] = qty + 1;
                                              qtyControllers[productId]?.text =
                                                  (qty + 1).toString();
                                            });
                                          },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 36,
                                    child: outOfStock
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Out of Stock',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: () {
                                              addToCart(
                                                productId,
                                                _parseAndClampQty(
                                                  productId,
                                                  stock,
                                                ),
                                              );
                                            },
                                            child: const Text('Add'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orangeAccent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProductDetail extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetail({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product Detail')),
      body: Center(child: Text('Product detail page placeholder')),
    );
  }
}
