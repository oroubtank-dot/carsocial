import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _addStory() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            GestureDetector(
              onTap: () => _pickImage(),
              child: const ListTile(
                leading: Icon(Icons.photo),
                title: Text('صورة'),
              ),
            ),
            GestureDetector(
              onTap: () => _pickVideo(),
              child: const ListTile(
                leading: Icon(Icons.videocam),
                title: Text('فيديو'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      await _uploadStory(File(image.path), 'image');
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) {
      await _uploadStory(File(video.path), 'video');
    }
  }

  Future<void> _uploadStory(File file, String type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final fileName =
          'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email,
        'userPhoto': user.photoURL ?? '',
        'mediaUrl': url,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة القصة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('القصص'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snapshot.data!.docs;

          final Map<String, List<QueryDocumentSnapshot>> userStories = {};
          for (var story in stories) {
            final userId = (story.data() as Map<String, dynamic>)['userId'];
            if (!userStories.containsKey(userId)) {
              userStories[userId] = [];
            }
            userStories[userId]!.add(story);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: _addStory,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[800],
                              border: Border.all(
                                color: const Color(0xFFFF6B00),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 30,
                                color: Colors.white,
                              ),
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
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'قصتك',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.grey),

              Expanded(
                child: ListView.builder(
                  itemCount: userStories.keys.length,
                  itemBuilder: (context, index) {
                    final userId = userStories.keys.elementAt(index);
                    final userStoryList = userStories[userId]!;
                    final firstStory =
                        userStoryList.first.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF6B00),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(firstStory['userPhoto'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        firstStory['userName'] ?? 'مستخدم',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${userStoryList.length} قصة',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryViewerScreen(
                              stories: userStoryList,
                              currentIndex: 0,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StoryViewerScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;
  final int currentIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.currentIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadMedia();
  }

  void _loadMedia() {
    _videoController?.dispose();
    final story = widget.stories[_currentIndex];
    final storyData = story.data() as Map<String, dynamic>;

    if (storyData['type'] == 'video') {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(storyData['mediaUrl']))
            ..initialize().then((_) {
              if (mounted) {
                setState(() {});
                _videoController!.play();
              }
            });
    } else {
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final _ = story.data() as Map<String, dynamic>;

    // لو مش بتستخدم storyData، امسح السطرين دول

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 2) {
            if (_currentIndex > 0) {
              setState(() {
                _currentIndex--;
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _loadMedia();
              });
            } else {
              Navigator.pop(context);
            }
          } else {
            if (_currentIndex < widget.stories.length - 1) {
              setState(() {
                _currentIndex++;
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _loadMedia();
              });
            } else {
              Navigator.pop(context);
            }
          }
        },
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _loadMedia();
            });
          },
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            final storyData = story.data() as Map<String, dynamic>;

            return Stack(
              children: [
                Center(
                  child:
                      storyData['type'] == 'video' &&
                          _videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : Image.network(
                          storyData['mediaUrl'],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                ),

                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          storyData['userPhoto'] ?? '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storyData['userName'] ?? 'مستخدم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatTime(storyData['createdAt'] as Timestamp?),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: _currentIndex >= index
                              ? Colors.white
                              : Colors.white54,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
