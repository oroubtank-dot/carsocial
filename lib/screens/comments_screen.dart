import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _commentRef = FirebaseFirestore.instance.collection('comments');

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _commentRef.add({
      'postId': widget.postId,
      'userId': user.uid,
      'userName': user.displayName ?? user.email,
      'userPhoto': user.photoURL ?? '',
      'text': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({
          'commentsCount': FieldValue.increment(1),
        });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التعليقات'),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentRef
                  .where('postId', isEqualTo: widget.postId)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;
                if (comments.isEmpty) {
                  return const Center(child: Text('لا توجد تعليقات بعد'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final data = comment.data() as Map<String, dynamic>;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: data['userPhoto'] != null && data['userPhoto'] != ''
                            ? NetworkImage(data['userPhoto'])
                            : null,
                        child: data['userPhoto'] == null || data['userPhoto'] == ''
                            ? Text(data['userName']?[0]?.toUpperCase() ?? 'U')
                            : null,
                      ),
                      title: Text(data['userName'] ?? 'مستخدم'),
                      subtitle: Text(data['text'] ?? ''),
                      trailing: Text(
                        _formatTime(data['createdAt']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليق...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0066CC)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}