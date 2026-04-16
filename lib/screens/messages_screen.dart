import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('لا توجد محادثات'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final otherUserId = (data['participants'] as List)
                  .firstWhere((id) => id != currentUser.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('جاري التحميل...'));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final userName = userData?['displayName'] ?? 'مستخدم';
                  final userPhoto = userData?['photoURL'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : null,
                      child: userPhoto.isEmpty
                          ? Text(userName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      data['lastMessage'] ?? 'ابدأ المحادثة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: data['unreadCount'] != null && data['unreadCount'] > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${data['unreadCount']}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            otherUserId: otherUserId,
                            otherUserName: userName,
                            otherUserPhoto: userPhoto,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}