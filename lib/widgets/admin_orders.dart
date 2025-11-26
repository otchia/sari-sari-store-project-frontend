import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders>
    with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool loading = true;
  String selectedFilter = "all"; // all, pending, pickup, delivery
  late TabController _tabController;

  // Statistics
  Map<String, dynamic> statistics = {};
  bool loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    fetchOrders();
    fetchStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
        fetchOrders(filter: "all");
        break;
      case 1:
        fetchOrders(filter: "pending");
        break;
      case 2:
        fetchOrders(filter: "pickup");
        break;
      case 3:
        fetchOrders(filter: "delivery");
        break;
    }
  }

  // ================= FETCH ORDERS =================
  Future<void> fetchOrders({String filter = "all"}) async {
    setState(() {
      loading = true;
      selectedFilter = filter;
    });

    try {
      String endpoint;
      switch (filter) {
        case "pending":
          endpoint = "http://localhost:5000/api/admin/orders/pending";
          break;
        case "pickup":
          endpoint = "http://localhost:5000/api/admin/orders/pickup";
          break;
        case "delivery":
          endpoint = "http://localhost:5000/api/admin/orders/delivery";
          break;
        default:
          endpoint = "http://localhost:5000/api/admin/orders";
      }

      print("🔵 Fetching orders with filter: $filter");
      print("   Endpoint: $endpoint");

      final response = await http.get(Uri.parse(endpoint));

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          orders = decoded['orders'] ?? [];
          loading = false;
        });
        print("✅ Loaded ${orders.length} orders");
      } else {
        setState(() => loading = false);
        print("❌ Failed to load orders");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Error fetching orders: $e");
    }
  }

  // ================= FETCH STATISTICS =================
  Future<void> fetchStatistics() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/admin/orders/statistics"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          statistics = decoded['statistics'] ?? {};
          loadingStats = false;
        });
        print("✅ Statistics loaded: $statistics");
      } else {
        setState(() => loadingStats = false);
      }
    } catch (e) {
      setState(() => loadingStats = false);
      print("❌ Error fetching statistics: $e");
    }
  }

  // ================= MARK READY FOR PICKUP (AC8) =================
  Future<void> markReadyForPickup(String orderId) async {
    try {
      print("🔵 Marking order as ready for pickup: $orderId");

      final response = await http.put(
        Uri.parse(
          "http://localhost:5000/api/admin/orders/$orderId/ready-for-pickup",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminNotes": "Order is ready for customer pickup"}),
      );

      if (response.statusCode == 200) {
        print("✅ Order marked as ready for pickup");
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Order marked as ready! Customer notified."),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh orders and stats
        fetchOrders(filter: selectedFilter);
        fetchStatistics();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Failed to update order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error marking ready: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= MARK OUT FOR DELIVERY =================
  Future<void> markOutForDelivery(String orderId) async {
    try {
      print("🔵 Marking order as out for delivery: $orderId");

      final response = await http.put(
        Uri.parse(
          "http://localhost:5000/api/admin/orders/$orderId/out-for-delivery",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminNotes": "Order is out for delivery"}),
      );

      if (response.statusCode == 200) {
        print("✅ Order marked as out for delivery");
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Order out for delivery! Customer notified."),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );

        fetchOrders(filter: selectedFilter);
        fetchStatistics();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Failed to update order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error marking out for delivery: $e");
    }
  }

  // ================= MARK COMPLETED (AC10) =================
  Future<void> markCompleted(String orderId) async {
    try {
      print("🔵 Marking order as completed: $orderId");

      final response = await http.put(
        Uri.parse("http://localhost:5000/api/admin/orders/$orderId/complete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminNotes": "Order completed successfully"}),
      );

      if (response.statusCode == 200) {
        print("✅ Order completed");
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Order completed! Customer notified."),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        fetchOrders(filter: selectedFilter);
        fetchStatistics();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Failed to complete order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error completing order: $e");
    }
  }

  // ================= CANCEL ORDER =================
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      print("🔵 Cancelling order: $orderId");

      final response = await http.put(
        Uri.parse("http://localhost:5000/api/admin/orders/$orderId/cancel"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reason": reason, "adminNotes": reason}),
      );

      if (response.statusCode == 200) {
        print("✅ Order cancelled");
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Order cancelled. Customer notified."),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );

        fetchOrders(filter: selectedFilter);
        fetchStatistics();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Failed to cancel order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error cancelling order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Statistics Cards
        if (!loadingStats) _buildStatistics(),

        const SizedBox(height: 24),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.brown,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "All Orders"),
              Tab(text: "Pending"),
              Tab(text: "Pick-up"),
              Tab(text: "Delivery"),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Orders List
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                  ),
                )
              : orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(orders[index]);
                      },
                    ),
        ),
      ],
    );
  }

  // ================= STATISTICS CARDS =================
  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              "Total Orders",
              statistics['total']?.toString() ?? "0",
              Icons.shopping_bag,
              Colors.blue,
            ),
            _buildStatCard(
              "Pending",
              statistics['pending']?.toString() ?? "0",
              Icons.schedule,
              Colors.orange,
            ),
            _buildStatCard(
              "Ready/In Transit",
              ((statistics['readyForPickup'] ?? 0) +
                      (statistics['outForDelivery'] ?? 0))
                  .toString(),
              Icons.local_shipping,
              Colors.purple,
            ),
            _buildStatCard(
              "Completed",
              statistics['completed']?.toString() ?? "0",
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              "Revenue",
              "₱${(statistics['totalRevenue'] ?? 0).toStringAsFixed(2)}",
              Icons.payments,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      width: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No orders yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Orders will appear here when customers place them",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ORDER CARD =================
  Widget _buildOrderCard(dynamic order) {
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final customerName = order['customerName']?.toString() ?? 'Guest';
    final totalAmount = double.tryParse(order['totalAmount']?.toString() ?? "0") ?? 0;
    final status = order['status']?.toString() ?? 'pending';
    final deliveryType = order['deliveryType']?.toString() ?? 'pickup';
    final paymentMethod = order['paymentMethod']?.toString() ?? 'cash';
    final items = order['items'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status).withOpacity(0.1),
                  _getStatusColor(status).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Order Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Order Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Order #$shortId",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₱${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          deliveryType == "pickup"
                              ? Icons.store
                              : Icons.delivery_dining,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          paymentMethod == "gcash"
                              ? Icons.account_balance_wallet
                              : Icons.payments,
                          size: 16,
                          color: paymentMethod == "gcash"
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Items
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Items (${items.length})",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${item['productName']} x${item['quantity']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Text(
                          "₱${(item['subtotal'] ?? 0).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "+${items.length - 3} more items",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Delivery Info
                if (deliveryType == "delivery" &&
                    order['deliveryAddress'] != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Delivery Address:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order['deliveryAddress']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (order['deliveryContactNumber'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    order['deliveryContactNumber'].toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Action Buttons (AC8)
                _buildActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons(dynamic order) {
    final status = order['status']?.toString() ?? 'pending';
    final deliveryType = order['deliveryType']?.toString() ?? 'pickup';
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';

    if (status == "completed" || status == "cancelled") {
      return Row(
        children: [
          Icon(
            status == "completed" ? Icons.check_circle : Icons.cancel,
            color: status == "completed" ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            status == "completed" ? "Order Completed" : "Order Cancelled",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: status == "completed" ? Colors.green : Colors.red,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Mark Ready/Out for Delivery
        if (status == "pending" && deliveryType == "pickup")
          ElevatedButton.icon(
            onPressed: () => markReadyForPickup(orderId),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text("Mark Ready for Pickup"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        if (status == "pending" && deliveryType == "delivery")
          ElevatedButton.icon(
            onPressed: () => markOutForDelivery(orderId),
            icon: const Icon(Icons.local_shipping, size: 18),
            label: const Text("Mark Out for Delivery"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        // Complete Order
        if (status == "ready_for_pickup" || status == "out_for_delivery")
          ElevatedButton.icon(
            onPressed: () => markCompleted(orderId),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text("Complete Order"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        // View Details
        OutlinedButton.icon(
          onPressed: () => _showOrderDetails(order),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text("View Details"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.brown,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Cancel Order
        if (status != "cancelled")
          OutlinedButton.icon(
            onPressed: () => _showCancelDialog(orderId),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text("Cancel"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }

  // ================= STATUS BADGE =================
  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "ready_for_pickup":
        return Colors.blue;
      case "out_for_delivery":
        return Colors.purple;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "pending":
        return "PENDING";
      case "ready_for_pickup":
        return "READY FOR PICKUP";
      case "out_for_delivery":
        return "OUT FOR DELIVERY";
      case "completed":
        return "COMPLETED";
      case "cancelled":
        return "CANCELLED";
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "pending":
        return Icons.schedule;
      case "ready_for_pickup":
        return Icons.shopping_bag;
      case "out_for_delivery":
        return Icons.local_shipping;
      case "completed":
        return Icons.check_circle;
      case "cancelled":
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  // ================= ORDER DETAILS DIALOG =================
  void _showOrderDetails(dynamic order) {
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final items = order['items'] as List<dynamic>? ?? [];
    final deliveryType = order['deliveryType']?.toString() ?? 'pickup';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.brown, size: 28),
                      const SizedBox(width: 12),
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
                              "Order #$shortId",
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

                  // Customer Info
                  _buildDetailRow(
                    "Customer",
                    order['customerName']?.toString() ?? 'Guest',
                    Icons.person,
                  ),
                  _buildDetailRow(
                    "Email",
                    order['customerEmail']?.toString() ?? 'N/A',
                    Icons.email,
                  ),
                  if (order['customerPhone'] != null &&
                      order['customerPhone'].toString().isNotEmpty)
                    _buildDetailRow(
                      "Phone",
                      order['customerPhone'].toString(),
                      Icons.phone,
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Order Info
                  _buildDetailRow(
                    "Delivery Type",
                    deliveryType == "pickup" ? "Pick-up" : "Delivery",
                    deliveryType == "pickup" ? Icons.store : Icons.delivery_dining,
                  ),
                  _buildDetailRow(
                    "Payment Method",
                    order['paymentMethod']?.toString() == "gcash"
                        ? "GCash"
                        : "Cash",
                    order['paymentMethod']?.toString() == "gcash"
                        ? Icons.account_balance_wallet
                        : Icons.payments,
                  ),
                  _buildDetailRow(
                    "Status",
                    _getStatusText(order['status']?.toString() ?? 'pending'),
                    _getStatusIcon(order['status']?.toString() ?? 'pending'),
                  ),

                  // Delivery Address
                  if (deliveryType == "delivery") ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Delivery Address:",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order['deliveryAddress']?.toString() ?? 'N/A',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (order['deliveryContactNumber'] != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone, color: Colors.grey[600], size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      order['deliveryContactNumber'].toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                              if (order['deliveryNotes'] != null &&
                                  order['deliveryNotes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Notes: ${order['deliveryNotes']}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Items List
                  const Text(
                    "Order Items",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₱${(item['productPrice'] ?? 0).toStringAsFixed(2)} × ${item['quantity']}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "₱${(item['subtotal'] ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CANCEL DIALOG =================
  void _showCancelDialog(String orderId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text("Cancel Order"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please provide a reason for cancellation:"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cancelOrder(
                orderId,
                reasonController.text.trim().isEmpty
                    ? "Cancelled by admin"
                    : reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Cancel Order"),
          ),
        ],
      ),
    );
  }
}

