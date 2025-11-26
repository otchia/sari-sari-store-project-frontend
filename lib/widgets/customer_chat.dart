import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class CustomerChat extends StatefulWidget {
  const CustomerChat({super.key});

  @override
  State<CustomerChat> createState() => _CustomerChatState();
}

class _CustomerChatState extends State<CustomerChat> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> messages = [];
  String? chatId;
  String? customerId;
  String customerName = '';
  bool isConnected = false;
  bool isTyping = false;
  bool loading = true;
  bool sending = false;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= INITIALIZE CHAT =================
  Future<void> _initializeChat() async {
    try {
      // Get customer ID from localStorage
      customerId = html.window.localStorage['customerId'];
      customerName = html.window.localStorage['customerName'] ?? 'Guest';

      if (customerId == null || customerId!.isEmpty) {
        print("❌ No customer ID found");
        setState(() => loading = false);
        return;
      }

      print("🔵 Initializing chat for customer: $customerId");

      // Fetch or create chat
      await _fetchChatHistory();

      // Initialize Socket.IO
      _initializeSocket();
    } catch (e) {
      print("❌ Error initializing chat: $e");
      setState(() => loading = false);
    }
  }

  // ================= FETCH CHAT HISTORY =================
  Future<void> _fetchChatHistory() async {
    try {
      print("🔵 Fetching chat history...");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/chat/$customerId/history"),
      );

      print("   Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          chatId = data['chat']['_id'];
          messages = data['chat']['messages'] ?? [];
          unreadCount = data['chat']['unreadCountCustomer'] ?? 0;
          loading = false;
        });
        print("✅ Chat history loaded: ${messages.length} messages");

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Mark messages as read
        if (unreadCount > 0) {
          _markAsRead();
        }
      } else {
        setState(() => loading = false);
        print("❌ Failed to fetch chat history");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Error fetching chat history: $e");
    }
  }

  // ================= INITIALIZE SOCKET =================
  void _initializeSocket() {
    print("🔵 Connecting to Socket.IO...");

    socket = IO.io(
      'http://localhost:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // Connection events
    socket.onConnect((_) {
      print("✅ Socket.IO connected!");
      setState(() => isConnected = true);

      // Join chat room
      socket.emit('join-chat', {
        'customerId': customerId,
        'userId': customerId,
        'userType': 'customer',
      });
    });

    socket.on('joined-chat', (data) {
      print("✅ Joined chat room: ${data['chatId']}");
      setState(() {
        chatId = data['chatId'];
      });
    });

    socket.onDisconnect((_) {
      print("❌ Socket.IO disconnected");
      setState(() => isConnected = false);
    });

    // Message events
    socket.on('receive-message', (data) {
      print("📩 New message received");
      final message = data['message'];

      // Check if this message is a duplicate (from our optimistic update)
      final isDuplicate = messages.any((msg) {
        return msg['message'] == message['message'] &&
            msg['senderType'] == message['senderType'] &&
            msg['senderId'] == message['senderId'] &&
            DateTime.parse(msg['timestamp'])
                    .difference(DateTime.parse(message['timestamp']))
                    .abs()
                    .inSeconds <
                5;
      });

      if (!isDuplicate) {
        setState(() {
          messages.add(message);
          unreadCount = data['unreadCountCustomer'] ?? 0;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        print("   Skipping duplicate message");
      }

      // Mark as read if chat is active (only for admin messages)
      if (mounted && message['senderType'] == 'admin') {
        _markAsRead();
      }
    });

    // Typing indicator
    socket.on('user-typing', (data) {
      if (data['userType'] == 'admin') {
        setState(() {
          isTyping = data['isTyping'];
        });
      }
    });

    // Messages marked as read
    socket.on('messages-read', (data) {
      print("✅ Messages marked as read");
      setState(() {
        unreadCount = data['unreadCountCustomer'] ?? 0;
      });
    });

    // Error handling
    socket.on('error', (data) {
      print("❌ Socket error: ${data['message']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // ================= SEND MESSAGE =================
  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isEmpty || chatId == null) return;

    setState(() => sending = true);

    print("🔵 Sending message...");

    // Create optimistic message (show immediately)
    final optimisticMessage = {
      'senderId': customerId,
      'senderType': 'customer',
      'senderName': customerName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
    };

    // Add message to UI immediately
    setState(() {
      messages.add(optimisticMessage);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send via socket
    socket.emit('send-message', {
      'chatId': chatId,
      'senderId': customerId,
      'senderType': 'customer',
      'message': message,
      'attachmentUrl': null,
      'attachmentType': 'none',
    });

    _messageController.clear();
    setState(() => sending = false);

    // Stop typing indicator
    socket.emit('typing', {
      'chatId': chatId,
      'userType': 'customer',
      'isTyping': false,
    });
  }

  // ================= MARK AS READ =================
  void _markAsRead() {
    if (chatId == null) return;

    socket.emit('mark-as-read', {'chatId': chatId, 'userType': 'customer'});
  }

  // ================= TYPING INDICATOR =================
  void _onTyping(String value) {
    if (chatId == null) return;

    socket.emit('typing', {
      'chatId': chatId,
      'userType': 'customer',
      'isTyping': value.isNotEmpty,
    });
  }

  // ================= SCROLL TO BOTTOM =================
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.brown.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildChatHeader(),

          // Messages
          Expanded(
            child: messages.isEmpty ? _buildEmptyState() : _buildMessagesList(),
          ),

          // Typing indicator
          if (isTyping) _buildTypingIndicator(),

          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ================= CHAT HEADER =================
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.brown,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Customer Support",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.greenAccent : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? "Online" : "Offline",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation with our support team",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ================= MESSAGES LIST =================
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCustomer = message['senderType'] == 'customer';
        final timestamp = DateTime.parse(
          message['timestamp']?.toString() ?? '',
        );
        final timeStr = DateFormat('hh:mm a').format(timestamp);

        return Align(
          alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: isCustomer
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isCustomer
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[200]!],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isCustomer
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isCustomer
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isCustomer
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isCustomer)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message['senderName'] ?? 'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      Text(
                        message['message'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: isCustomer ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (isCustomer) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message['read'] == true ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message['read'] == true
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= TYPING INDICATOR =================
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Icon(Icons.circle, size: 8, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Icon(Icons.circle, size: 8, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            "Admin is typing...",
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MESSAGE INPUT =================
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: _onTyping,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: sending ? null : _sendMessage,
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              tooltip: "Send",
            ),
          ),
        ],
      ),
    );
  }
}
