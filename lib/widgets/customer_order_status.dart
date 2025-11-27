import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class CustomerOrderStatus extends StatefulWidget {
  const CustomerOrderStatus({super.key});

  @override
  State<CustomerOrderStatus> createState() => _CustomerOrderStatusState();
}

class _CustomerOrderStatusState extends State<CustomerOrderStatus> {
  List<dynamic> activeOrders = [];
  bool loading = true;
  String? customerId;

  @override
  void initState() {
    super.initState();
    customerId = html.window.localStorage['customerId'];
    fetchActiveOrders();

    // Auto-refresh every 30 seconds
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) {
        fetchActiveOrders();
        return true;
      }
      return false;
    });
  }

  Future<void> fetchActiveOrders() async {
    if (customerId == null || customerId!.isEmpty) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);

    try {
      print("🔵 Fetching active orders for customer: $customerId");

      final response = await http.get(
        Uri.parse(
          "http://localhost:5000/api/orders/customer/$customerId/active",
        ),
      );

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          activeOrders = decoded['orders'] ?? [];
          loading = false;
        });
        print("✅ Loaded ${activeOrders.length} active orders");
      } else {
        setState(() => loading = false);
        print("❌ Failed to load active orders");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Error fetching active orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
        ),
      );
    }

    if (activeOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: fetchActiveOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          return _buildOrderCard(order);
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
              Icons.local_shipping,
              size: 80,
              color: Color(0xFFFF6F00),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Active Orders",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your current orders and deliveries will appear here",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: fetchActiveOrders,
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

  Widget _buildOrderCard(dynamic order) {
    final orderId = order['_id'] ?? '';
    final items = order['items'] ?? [];
    final totalAmount = order['totalAmount'] ?? 0;
    final deliveryType = order['deliveryType'] ?? 'pickup';
    final status = order['status'] ?? 'pending';
    final createdAt = order['createdAt'] ?? '';
    final deliveryAddress = order['deliveryAddress'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderTracking(order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, _getStatusColor(status).withOpacity(0.05)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Indicator
              _buildProgressIndicator(status),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Delivery Info
              if (deliveryType == 'delivery' && deliveryAddress != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliveryAddress,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Items Summary
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${items.length} item${items.length != 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₱${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showOrderTracking(order),
                  icon: const Icon(Icons.track_changes, size: 18),
                  label: const Text(
                    "Track Order",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String status) {
    final steps = _getOrderSteps(status);
    final currentStep = _getCurrentStep(status);

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? _getStatusColor(status)
                            : Colors.grey[300],
                      ),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? _getStatusColor(status)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? _getStatusColor(status)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? _getStatusColor(status)
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getStatusMessage(status),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(status),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<String> _getOrderSteps(String status) {
    return ['Pending', 'Processing', 'Ready', 'Completed'];
  }

  int _getCurrentStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return 2;
      case 'completed':
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order received - Waiting for confirmation';
      case 'processing':
        return 'Order is being prepared';
      case 'ready_for_pickup':
        return 'Order is ready for pickup!';
      case 'out_for_delivery':
        return 'Order is out for delivery';
      case 'completed':
        return 'Order completed - Thank you!';
      case 'delivered':
        return 'Order delivered successfully!';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'ready_for_pickup':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.purple;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.check_circle;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'completed':
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ready_for_pickup':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showOrderTracking(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                      color: _getStatusColor(order['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(order['status']),
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
                          "Order Tracking",
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

              // Status Timeline
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineItem(
                        "Order Placed",
                        "Your order has been received",
                        Icons.shopping_cart,
                        true,
                        order['createdAt'],
                      ),
                      _buildTimelineItem(
                        "Processing",
                        "Your order is being prepared",
                        Icons.restaurant,
                        _getCurrentStep(order['status']) >= 1,
                        order['updatedAt'],
                      ),
                      if (order['deliveryType'] == 'delivery')
                        _buildTimelineItem(
                          "Out for Delivery",
                          "Your order is on its way",
                          Icons.delivery_dining,
                          _getCurrentStep(order['status']) >= 2,
                          null,
                        )
                      else
                        _buildTimelineItem(
                          "Ready for Pickup",
                          "Your order is ready to be picked up",
                          Icons.check_circle,
                          _getCurrentStep(order['status']) >= 2,
                          null,
                        ),
                      _buildTimelineItem(
                        "Completed",
                        order['deliveryType'] == 'delivery'
                            ? "Order delivered successfully"
                            : "Order picked up",
                        Icons.check_circle_outline,
                        _getCurrentStep(order['status']) >= 3,
                        order['completedAt'],
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),
              const SizedBox(height: 16),

              // Order Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₱${(order['totalAmount'] ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6F00),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: fetchActiveOrders,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Refresh"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
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

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    bool isCompleted,
    String? timestamp, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFFF6F00) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? const Color(0xFFFF6F00) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (timestamp != null && isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
