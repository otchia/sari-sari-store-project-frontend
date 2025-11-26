import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class AdminChat extends StatefulWidget {
  const AdminChat({super.key});

  @override
  State<AdminChat> createState() => _AdminChatState();
}

class _AdminChatState extends State<AdminChat> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> chatsList = [];
  List<dynamic> currentMessages = [];
  dynamic selectedChat;
  String? adminId;
  String adminName = '';
  bool isConnected = false;
  bool isTyping = false;
  bool loading = true;
  bool loadingMessages = false;
  bool sending = false;
  int totalUnread = 0;

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

  // ================= INITIALIZE =================
  Future<void> _initializeChat() async {
    try {
      adminId = html.window.localStorage['adminId'];
      adminName = html.window.localStorage['adminUsername'] ?? 'Admin';

      if (adminId == null || adminId!.isEmpty) {
        print("❌ No admin ID found");
        setState(() => loading = false);
        return;
      }

      print("🔵 Initializing admin chat...");

      await _fetchAllChats();
      _initializeSocket();
    } catch (e) {
      print("❌ Error initializing chat: $e");
      setState(() => loading = false);
    }
  }

  // ================= FETCH ALL CHATS =================
  Future<void> _fetchAllChats() async {
    try {
      print("🔵 Fetching all chats...");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/admin/chats?status=active"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          chatsList = data['chats'] ?? [];
          loading = false;
        });
        print("✅ Loaded ${chatsList.length} chats");

        // Fetch unread count
        _fetchUnreadCount();
      } else {
        setState(() => loading = false);
        print("❌ Failed to fetch chats");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Error fetching chats: $e");
    }
  }

  // ================= FETCH UNREAD COUNT =================
  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/admin/chats/unread-count"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalUnread = data['totalUnread'] ?? 0;
        });
      }
    } catch (e) {
      print("❌ Error fetching unread count: $e");
    }
  }

  // ================= FETCH CHAT DETAILS =================
  Future<void> _fetchChatDetails(String chatId) async {
    setState(() => loadingMessages = true);

    try {
      print("🔵 Fetching chat details for: $chatId");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/admin/chats/$chatId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentMessages = data['chat']['messages'] ?? [];
          loadingMessages = false;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Mark as read
        _markAsRead(chatId);

        // Join this chat room via socket
        socket.emit('join-chat', {
          'customerId': selectedChat['customerId'],
          'userId': adminId,
          'userType': 'admin',
        });
      } else {
        setState(() => loadingMessages = false);
      }
    } catch (e) {
      setState(() => loadingMessages = false);
      print("❌ Error fetching chat details: $e");
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

    socket.onConnect((_) {
      print("✅ Socket.IO connected (Admin)");
      setState(() => isConnected = true);
    });

    socket.onDisconnect((_) {
      print("❌ Socket.IO disconnected");
      setState(() => isConnected = false);
    });

    // Receive messages
    socket.on('receive-message', (data) {
      print("📩 New message received");
      final message = data['message'];
      final chatId = data['chatId'];

      // Update current chat if it's selected
      if (selectedChat != null && selectedChat['_id'] == chatId) {
        // Check if this message is a duplicate (from our optimistic update)
        final isDuplicate = currentMessages.any((msg) {
          return msg['message'] == message['message'] &&
              msg['senderType'] == message['senderType'] &&
              msg['senderId'] == message['senderId'] &&
              DateTime.parse(msg['timestamp'])
                  .difference(DateTime.parse(message['timestamp']))
                  .abs()
                  .inSeconds < 5;
        });

        if (!isDuplicate) {
          setState(() {
            currentMessages.add(message);
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          print("   Skipping duplicate message");
        }

        // Auto mark as read (only for customer messages)
        if (message['senderType'] == 'customer') {
          _markAsRead(chatId);
        }
      }

      // Update chat list
      _updateChatInList(chatId, data);
      _fetchUnreadCount();
    });

    // Typing indicator
    socket.on('user-typing', (data) {
      if (data['userType'] == 'customer') {
        setState(() {
          isTyping = data['isTyping'];
        });
      }
    });

    // Messages marked as read
    socket.on('messages-read', (data) {
      _fetchUnreadCount();
      _fetchAllChats();
    });

    socket.on('error', (data) {
      print("❌ Socket error: ${data['message']}");
    });
  }

  // ================= UPDATE CHAT IN LIST =================
  void _updateChatInList(String chatId, dynamic data) {
    setState(() {
      final index = chatsList.indexWhere((chat) => chat['_id'] == chatId);
      if (index != -1) {
        chatsList[index]['lastMessage'] = data['message']['message'];
        chatsList[index]['lastMessageAt'] = data['message']['timestamp'];
        chatsList[index]['unreadCountAdmin'] = data['unreadCountAdmin'] ?? 0;

        // Move to top
        final chat = chatsList.removeAt(index);
        chatsList.insert(0, chat);
      }
    });
  }

  // ================= SEND MESSAGE =================
  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isEmpty || selectedChat == null) return;

    setState(() => sending = true);

    // Create optimistic message (show immediately)
    final optimisticMessage = {
      'senderId': adminId,
      'senderType': 'admin',
      'senderName': adminName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
    };

    // Add message to UI immediately
    setState(() {
      currentMessages.add(optimisticMessage);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send via socket
    socket.emit('send-message', {
      'chatId': selectedChat['_id'],
      'senderId': adminId,
      'senderType': 'admin',
      'message': message,
      'attachmentUrl': null,
      'attachmentType': 'none',
    });

    _messageController.clear();
    setState(() => sending = false);

    // Stop typing
    socket.emit('typing', {
      'chatId': selectedChat['_id'],
      'userType': 'admin',
      'isTyping': false,
    });
  }

  // ================= MARK AS READ =================
  Future<void> _markAsRead(String chatId) async {
    try {
      await http.put(
        Uri.parse("http://localhost:5000/api/admin/chats/$chatId/read"),
      );

      socket.emit('mark-as-read', {
        'chatId': chatId,
        'userType': 'admin',
      });

      _fetchUnreadCount();
      _fetchAllChats();
    } catch (e) {
      print("❌ Error marking as read: $e");
    }
  }

  // ================= TYPING INDICATOR =================
  void _onTyping(String value) {
    if (selectedChat == null) return;

    socket.emit('typing', {
      'chatId': selectedChat['_id'],
      'userType': 'admin',
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
        ),
      );
    }

    return Row(
      children: [
        // Chat List (Left Panel)
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildChatsHeader(),
              Expanded(
                child: chatsList.isEmpty
                    ? _buildEmptyChats()
                    : _buildChatsList(),
              ),
            ],
          ),
        ),

        // Conversation (Right Panel)
        Expanded(
          child: selectedChat == null
              ? _buildNoSelectionView()
              : _buildConversationView(),
        ),
      ],
    );
  }

  // ================= CHATS HEADER =================
  Widget _buildChatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Customer Chats",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (totalUnread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                totalUnread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? Colors.greenAccent : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY CHATS =================
  Widget _buildEmptyChats() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No customer chats yet",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ================= CHATS LIST =================
  Widget _buildChatsList() {
    return ListView.builder(
      itemCount: chatsList.length,
      itemBuilder: (context, index) {
        final chat = chatsList[index];
        final isSelected = selectedChat != null && selectedChat['_id'] == chat['_id'];
        final unread = chat['unreadCountAdmin'] ?? 0;
        final lastMessageTime = chat['lastMessageAt'] != null
            ? DateTime.parse(chat['lastMessageAt'])
            : null;
        final timeStr = lastMessageTime != null
            ? _formatTime(lastMessageTime)
            : '';

        return InkWell(
          onTap: () {
            setState(() {
              selectedChat = chat;
            });
            _fetchChatDetails(chat['_id']);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD32F2F).withOpacity(0.1) : null,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.primaries[index % Colors.primaries.length],
                        Colors.primaries[index % Colors.primaries.length].shade700,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (chat['customerName'] ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['customerName'] ?? 'Customer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['lastMessage'] ?? 'No messages yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: unread > 0 ? Colors.black87 : Colors.grey[600],
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= NO SELECTION VIEW =================
  Widget _buildNoSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Select a chat to start messaging",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ================= CONVERSATION VIEW =================
  Widget _buildConversationView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[100]!, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Conversation Header
          _buildConversationHeader(),

          // Messages
          Expanded(
            child: loadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                    ),
                  )
                : currentMessages.isEmpty
                    ? _buildEmptyConversation()
                    : _buildMessagesList(),
          ),

          // Typing indicator
          if (isTyping) _buildTypingIndicator(),

          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ================= CONVERSATION HEADER =================
  Widget _buildConversationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (selectedChat['customerName'] ?? 'C')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedChat['customerName'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedChat['customerEmail'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _fetchChatDetails(selectedChat['_id']),
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
    );
  }

  // ================= EMPTY CONVERSATION =================
  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No messages in this chat",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
      itemCount: currentMessages.length,
      itemBuilder: (context, index) {
        final message = currentMessages[index];
        final isAdmin = message['senderType'] == 'admin';
        final timestamp = DateTime.parse(message['timestamp']?.toString() ?? '');
        final timeStr = DateFormat('hh:mm a').format(timestamp);

        return Align(
          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            child: Column(
              crossAxisAlignment:
                  isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isAdmin
                        ? const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[200]!],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAdmin
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isAdmin
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
                    crossAxisAlignment: isAdmin
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message['senderName'] ?? 'Customer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      Text(
                        message['message'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: isAdmin ? Colors.white : Colors.black87,
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
                    if (isAdmin) ...[
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
            "Customer is typing...",
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
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
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
                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
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

  // ================= FORMAT TIME =================
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

