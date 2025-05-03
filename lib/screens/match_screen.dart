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
  bool noMoreProfiles = false;

  @override
  void initState() {
    super.initState();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final likesSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('likes')
            .get();

    final skippedSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('skipped')
            .get();

    final likedIds = likesSnapshot.docs.map((doc) => doc.id).toSet();
    final skippedIds = skippedSnapshot.docs.map((doc) => doc.id).toSet();

    final alreadySeenIds = {...likedIds, ...skippedIds};

    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final allProfiles =
        snapshot.docs
            .where(
              (doc) =>
                  doc.id != currentUser.uid && !alreadySeenIds.contains(doc.id),
            )
            .toList();

    setState(() {
      profiles = allProfiles;
      currentIndex = 0;
      noMoreProfiles = profiles.isEmpty;
    });
  }

  Future<void> handleMatch(bool isAccepted) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentIndex >= profiles.length) return;

    final targetProfile = profiles[currentIndex];
    final targetUserId = targetProfile.id;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    if (isAccepted) {
      await userDoc.collection('likes').doc(targetUserId).set({
        'timestamp': Timestamp.now(),
      });
      // Check for mutual match
      final targetLike =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('likes')
              .doc(currentUser.uid)
              .get();

      if (targetLike.exists) {
        final sortedIds = [currentUser.uid, targetUserId]..sort();
        final matchId = "${sortedIds[0]}_${sortedIds[1]}";
        await FirebaseFirestore.instance.collection('matches').doc(matchId).set(
          {'userIds': sortedIds, 'timestamp': Timestamp.now()},
        );
        await FirebaseFirestore.instance.collection('chats').doc(matchId).set({
          'userIds': sortedIds,
        });

        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("It's a Match!"),
                content: const Text(
                  "You both liked each other! Start chatting now.",
                ),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    } else {
      await userDoc.collection('skipped').doc(targetUserId).set({
        'timestamp': Timestamp.now(),
      });
    }

    setState(() {
      profiles.removeAt(currentIndex);
      if (profiles.isEmpty) {
        noMoreProfiles = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (noMoreProfiles) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Matching Screen"),
          backgroundColor: Colors.purple,
        ),
        body: const Center(
          child: Text(
            "Sorry, there are no more profiles to view currently",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

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
                Center(child: Text('Age: ${profile['age'] ?? 'N/A'}')),
                Center(child: Text('Sex: ${profile['sex'] ?? 'N/A'}')),
                const SizedBox(height: 24),
                Text(
                  'Favorite past destination(s):\n${profile['favoriteDestinations'] ?? ''}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Bucket-list destinations:\n${profile['bucketList'] ?? ''}',
                ),
                const SizedBox(height: 12),
                Text('Bucket-list thrills:\n${profile['thrills'] ?? ''}'),
                const SizedBox(height: 12),
                Text(
                  'Dates wanting to travel:\n${profile['travelDates'] ?? ''}',
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
