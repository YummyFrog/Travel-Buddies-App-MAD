import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> users = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    final currentUser = _auth.currentUser;

    final snapshot = await _firestore.collection('users').get();

    final allUsers =
        snapshot.docs.where((doc) => doc.id != currentUser?.uid).toList();

    setState(() {
      users = allUsers;
      isLoading = false;
    });
  }

  void handleSwipe(bool isAccepted) async {
    if (users.isEmpty || currentIndex >= users.length) return;

    final currentUser = _auth.currentUser;
    final swipedUserId = users[currentIndex].id;

    final action = isAccepted ? 'likes' : 'dislikes';

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection(action)
        .doc(swipedUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    setState(() {
      currentIndex++;
    });
  }

  Widget buildUserCard(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Matching Screen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              data['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Age: ${data['age'] ?? 'N/A'}'),
            Text('Sex: ${data['sex'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text(
              'Favorite past destination(s): ${data['favoriteDestinations'] ?? ''}',
            ),
            Text('Bucket-list destinations: ${data['bucketList'] ?? ''}'),
            Text('Bucket-list thrills: ${data['thrills'] ?? ''}'),
            Text('Dates wanting to travel: ${data['travelDates'] ?? ''}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 36),
                  onPressed: () => handleSwipe(false),
                ),
                IconButton(
                  icon: const Icon(Icons.check, size: 36),
                  onPressed: () => handleSwipe(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // the 'hands' icon is selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.pan_tool), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ''),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : (currentIndex >= users.length
                  ? const Center(child: Text('No more users to show.'))
                  : buildUserCard(users[currentIndex])),
    );
  }
}
