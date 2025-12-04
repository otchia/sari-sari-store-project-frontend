import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class CustomerPurchaseHistory extends StatefulWidget {
  const CustomerPurchaseHistory({super.key});

  @override
  State<CustomerPurchaseHistory> createState() =>
      _CustomerPurchaseHistoryState();
}

class _CustomerPurchaseHistoryState extends State<CustomerPurchaseHistory> {
  List<dynamic> purchases = [];
  bool loading = true;
  String? customerId;

  @override
  void initState() {
    super.initState();
    customerId = html.window.localStorage['customerId'];
    fetchPurchaseHistory();
  }

  Future<void> fetchPurchaseHistory() async {
    if (customerId == null || customerId!.isEmpty) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);

    try {
      print("🔵 Fetching purchase history for customer: $customerId");

      final response = await http.get(
        Uri.parse(
          "http://localhost:5000/api/orders/customer/$customerId/history",
        ),
      );

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          purchases = decoded['orders'] ?? [];
          loading = false;
        });
        print("✅ Loaded ${purchases.length} purchases");
      } else {
        setState(() => loading = false);
        print("❌ Failed to load purchase history");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Error fetching purchase history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
        ),
      );
    }

    if (purchases.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: fetchPurchaseHistory,
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final purchase = purchases[index];
          return _buildPurchaseCard(purchase, isMobile: isMobile);
        },
      ),
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
              color: const Color(0xFFFF6F00).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 80,
              color: Color(0xFFFF6F00),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Purchase History",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your completed orders will appear here",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: fetchPurchaseHistory,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(dynamic purchase, {required bool isMobile}) {
    final orderId = purchase['_id'] ?? '';
    final items = purchase['items'] ?? [];
    final totalAmount = purchase['totalAmount'] ?? 0;
    final deliveryType = purchase['deliveryType'] ?? 'pickup';
    final paymentMethod = purchase['paymentMethod'] ?? 'cash';
    final status = purchase['status'] ?? 'completed';
    final completedAt = purchase['completedAt'] ?? purchase['updatedAt'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderDetails(purchase),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text(
                          _formatDate(completedAt),
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, isMobile: isMobile),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              const Divider(),
              SizedBox(height: isMobile ? 10 : 12),

              // Items Summary
              Text(
                "${items.length} item${items.length != 1 ? 's' : ''}",
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${item['quantity']}x ${item['productName'] ?? 'Item'}",
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "... and ${items.length - 2} more item${items.length - 2 != 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              SizedBox(height: isMobile ? 12 : 16),

              // Bottom Row
              Row(
                children: [
                  Icon(
                    deliveryType == 'delivery'
                        ? Icons.delivery_dining
                        : Icons.shopping_bag_outlined,
                    size: isMobile ? 16 : 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Text(
                    deliveryType == 'delivery' ? 'Delivery' : 'Pickup',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Icon(
                    Icons.payment,
                    size: isMobile ? 16 : 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Text(
                    paymentMethod.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₱${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {required bool isMobile}) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        displayText = 'Completed';
        break;
      case 'delivered':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        displayText = 'Delivered';
        break;
      case 'cancelled':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: isMobile ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showOrderDetails(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Details",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Order #${(order['_id'] ?? '').substring((order['_id'] ?? '').length > 8 ? (order['_id'] ?? '').length - 8 : 0)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Items List
              const Text(
                "Items Ordered",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...(order['items'] ?? []).map<Widget>((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'] ?? 'Item',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Qty: ${item['quantity']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₱${((item['price'] ?? 0) * (item['quantity'] ?? 0)).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
              
              const Divider(),
              const SizedBox(height: 16),
              
              // Order Info
              _buildInfoRow("Delivery Type", order['deliveryType'] == 'delivery' ? 'Delivery' : 'Pickup'),
              _buildInfoRow("Payment Method", (order['paymentMethod'] ?? 'cash').toUpperCase()),
              _buildInfoRow("Status", order['status'] ?? ''),
              if (order['deliveryAddress'] != null)
                _buildInfoRow("Delivery Address", order['deliveryAddress']),
              
              const Divider(),
              const SizedBox(height: 16),
              
              // Total
              Row(
                children: [
                  const Text(
                    "Total Amount:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₱${(order['totalAmount'] ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

