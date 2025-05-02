import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> profiles = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final allProfiles = snapshot.docs;

    setState(() {
      profiles =
          allProfiles
              .where((doc) => doc.id != currentUser.uid) // exclude self
              .toList();
    });
  }

  void handleMatch(bool isAccepted) {
    // TODO: Save match/skip decision to Firestore here
    setState(() {
      if (currentIndex < profiles.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0; // loop back or show "No more profiles"
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = profiles[currentIndex].data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 209, 240),
      appBar: AppBar(
        title: const Text('Matching Screen'),
        backgroundColor: Colors.purple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    profile['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Age: ${profile['age'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Center(
                  child: Text(
                    'Sex: ${profile['sex'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Favorite past destination(s):\n${profile['favoriteDestinations'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bucket-list destinations:\n${profile['bucketList'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bucket-list thrills:\n${profile['thrills'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dates wanting to travel:\n${profile['travelDates'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 36),
                      onPressed: () => handleMatch(false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, size: 36),
                      onPressed: () => handleMatch(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
