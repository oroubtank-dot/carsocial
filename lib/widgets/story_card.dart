import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../screens/story_viewer_screen.dart';

class StoryCard extends StatefulWidget {
  final bool isAddStory;
  final String? userId;
  final String? userName;
  final String? userPhoto;

  const StoryCard({
    super.key,
    required this.isAddStory,
    this.userId,
    this.userName,
    this.userPhoto,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _addStory() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      await _uploadStory(File(pickedFile.path));
    }
  }

  Future<void> _uploadStory(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('جاري رفع القصة...')));
    }

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'مستخدم',
        'userPhoto': user.photoURL ?? '',
        'mediaUrl': url,
        'mediaType': 'image',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة القصة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إضافة القصة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewStories() async {
    if (widget.userId == null) return;

    final storiesSnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: widget.userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .get();

    if (storiesSnapshot.docs.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StoryViewerScreen(stories: storiesSnapshot.docs, initialIndex: 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isAddStory ? _addStory : _viewStories,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: widget.isAddStory
                        ? null
                        : const LinearGradient(
                            colors: [Colors.red, Colors.orange, Colors.purple],
                          ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.isAddStory
                        ? null
                        : (widget.userPhoto != null &&
                                  widget.userPhoto!.isNotEmpty
                              ? NetworkImage(widget.userPhoto!)
                              : null),
                    child: widget.isAddStory
                        ? const Icon(
                            Icons.add,
                            size: 30,
                            color: Color(0xFF0A2E5C),
                          )
                        : (widget.userPhoto == null || widget.userPhoto!.isEmpty
                              ? Text(
                                  widget.userName != null &&
                                          widget.userName!.isNotEmpty
                                      ? widget.userName![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black54,
                                  ),
                                )
                              : null),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.isAddStory
                  ? 'your_story'.tr()
                  : (widget.userName ?? 'user'.tr()),
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
