import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _announcementController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

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

    // Generate unique chatRoomId
    final chatRoomId =
        currentUserId.compareTo(otherUserId) < 0
            ? '$currentUserId\_$otherUserId'
            : '$otherUserId\_$currentUserId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PrivateChatScreen(
              chatRoomId: chatRoomId,
              otherUserName: otherUserName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Public Announcement Section
            const Text(
              "Public Announcements",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                stream:
                    FirebaseFirestore.instance
                        .collection('announcements')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
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
            const Text(
              "Matches",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('matches')
                        .where('userIds', arrayContains: currentUser?.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final matchDocs = snapshot.data!.docs;

                  final otherUserIds =
                      matchDocs.map((doc) {
                        final ids = List<String>.from(doc['userIds']);
                        ids.remove(currentUser!.uid);
                        return ids.first;
                      }).toList();

                  if (otherUserIds.isEmpty) {
                    return const Center(child: Text("No matches yet."));
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance.collection('users').get(),
                    builder: (context, usersSnapshot) {
                      if (!usersSnapshot.hasData)
                        return const CircularProgressIndicator();
                      final allUsers = usersSnapshot.data!.docs;
                      final matchedUsers =
                          allUsers
                              .where((doc) => otherUserIds.contains(doc.id))
                              .toList();

                      return ListView.builder(
                        itemCount: matchedUsers.length,
                        itemBuilder: (context, index) {
                          final user = matchedUsers[index];
                          final name = user['name'] ?? 'Unnamed';
                          return ListTile(
                            title: Text(name),
                            trailing: const Icon(Icons.chat_bubble_outline),
                            onTap: () => _startPrivateChat(user.id, name),
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

// ----------------- Private Chat Screen -----------------

class PrivateChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;

  const PrivateChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUser?.uid,
          'text': text,
          'timestamp': Timestamp.now(),
        });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.otherUserName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUser?.uid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
