// chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _announcementController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  int _totalUnread = 0;
  late StreamSubscription _matchesSubscription;

  @override
  void initState() {
    super.initState();
    _initFCM();
    _setupUnreadListener();
  }

  @override
  void dispose() {
    _matchesSubscription.cancel();
    super.dispose();
  }

  void _setupUnreadListener() {
    _matchesSubscription = FirebaseFirestore.instance
        .collection('matches')
        .where('userIds', arrayContains: currentUser?.uid)
        .snapshots()
        .listen((_) => _updateTotalUnread());
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${message.notification!.title}: ${message.notification!.body}",
            ),
          ),
        );
      }
      _updateTotalUnread();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification opened the app.");
      _updateTotalUnread();
    });
  }

  void _postAnnouncement() async {
    final text = _announcementController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('announcements').add({
      'userId': currentUser?.uid,
      'name': currentUser?.displayName ?? 'Anonymous',
      'text': text,
      'timestamp': Timestamp.now(),
    });

    _announcementController.clear();
  }

  void _startPrivateChat(String otherUserId, String otherUserName) async {
    final currentUserId = currentUser!.uid;
    final chatRoomId = currentUserId.compareTo(otherUserId) < 0
        ? '$currentUserId\_$otherUserId'
        : '$otherUserId\_$currentUserId';

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('metadata')
        .doc(currentUserId)
        .set({'lastOpened': Timestamp.now()});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(
          chatRoomId: chatRoomId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    ).then((_) => _updateTotalUnread());
  }

  Future<int> _getUnreadCount(String otherUserId) async {
    final currentUserId = currentUser!.uid;
    final chatRoomId = currentUserId.compareTo(otherUserId) < 0
        ? '$currentUserId\_$otherUserId'
        : '$otherUserId\_$currentUserId';

    final metaSnap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('metadata')
        .doc(currentUserId)
        .get();

    Timestamp lastOpened = metaSnap.exists
        ? metaSnap['lastOpened']
        : Timestamp.fromMillisecondsSinceEpoch(0);

    final messagesSnap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('timestamp', isGreaterThan: lastOpened)
        .get();

    return messagesSnap.docs.length;
  }

  Future<void> _updateTotalUnread() async {
    final matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('userIds', arrayContains: currentUser?.uid)
        .get();

    final otherUserIds = matchesSnapshot.docs.map((doc) {
      final ids = List<String>.from(doc['userIds']);
      ids.remove(currentUser!.uid);
      return ids.first;
    }).toList();

    int total = 0;
    for (String otherUserId in otherUserIds) {
      final count = await _getUnreadCount(otherUserId);
      total += count;
    }

    if (mounted) {
      setState(() {
        _totalUnread = total;
      });
    }
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      width: count > 9 ? 24 : 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          if (_totalUnread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildUnreadBadge(_totalUnread),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text("Public Announcements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _announcementController,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postAnnouncement,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final posts = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(post['name'] ?? 'Unknown'),
                          subtitle: Text(post['text']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 20, thickness: 2),
            const Text("Matches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_totalUnread > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "You have $_totalUnread unread message(s)",
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('userIds', arrayContains: currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final matchDocs = snapshot.data!.docs;

                  final otherUserIds = matchDocs.map((doc) {
                    final ids = List<String>.from(doc['userIds']);
                    ids.remove(currentUser!.uid);
                    return ids.first;
                  }).toList();

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('users').get(),
                    builder: (context, usersSnapshot) {
                      if (!usersSnapshot.hasData) return const CircularProgressIndicator();
                      final allUsers = usersSnapshot.data!.docs;
                      final matchedUsers = allUsers
                          .where((doc) => otherUserIds.contains(doc.id))
                          .toList();

                      return ListView.builder(
                        itemCount: matchedUsers.length,
                        itemBuilder: (context, index) {
                          final user = matchedUsers[index];
                          final name = user['name'] ?? 'Unnamed';
                          final otherUserId = user.id;

                          return FutureBuilder<int>(
                            future: _getUnreadCount(otherUserId),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;

                              return ListTile(
                                title: Text(name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (unreadCount > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: _buildUnreadBadge(unreadCount),
                                      ),
                                    const Icon(Icons.chat_bubble_outline),
                                  ],
                                ),
                                onTap: () => _startPrivateChat(otherUserId, name),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;

  const PrivateChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markChatAsOpened();
  }

  void _markChatAsOpened() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('metadata')
        .doc(currentUser!.uid)
        .set({'lastOpened': Timestamp.now()});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
    _markChatAsOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.otherUserName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}