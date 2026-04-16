import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';
import '../screens/chat_screen.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _checkIfSaved();
  }

  void _initVideo() {
    final data = widget.post.data() as Map<String, dynamic>;
    if (data['mediaType'] == 'video' &&
        data['mediaUrls'] != null &&
        data['mediaUrls'].isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(data['mediaUrls'][0]),
      );
      _videoController!.initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      });
    }
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_posts')
        .doc(widget.post.id)
        .get();

    if (mounted) {
      setState(() {
        _isSaved = doc.exists;
      });
    }
  }

  Future<void> _toggleSavePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredMessage(context);
      return;
    }

    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_posts')
        .doc(widget.post.id);

    if (_isSaved) {
      await savedRef.delete();
      setState(() {
        _isSaved = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ تم إزالة من المحفوظات')),
        );
      }
    } else {
      await savedRef.set({
        'postId': widget.post.id,
        'savedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isSaved = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الحفظ في المفضلة')),
        );
      }
    }
  }

  Future<void> _startChat(BuildContext context, String otherUserId,
      String otherUserName, String otherUserPhoto) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showLoginRequiredMessage(context);
      return;
    }

    String chatId = currentUser.uid.compareTo(otherUserId) < 0
        ? '${currentUser.uid}_$otherUserId'
        : '${otherUserId}_${currentUser.uid}';

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser.uid, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserPhoto: otherUserPhoto,
          ),
        ),
      );
    }
  }

  void _showLoginRequiredMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _sharePost(Map<String, dynamic> data) {
    final title = data['title'] ?? 'CarSocial Post';
    final description = data['description'] ?? '';
    final price = data['price'] ?? '';

    final text = '''
🚗 *$title*
📝 $description
💰 ${'price'.tr()}: $price ${'egp'.tr()}

${'download_app'.tr()}: CarSocial
''';

    Share.share(text);
  }

  void _showRatingDialog(BuildContext context, String postId) {
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('rate_post'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => rating = index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: rating > 0
                  ? () async {
                      Navigator.pop(context);
                      await _submitRating(postId, rating);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shadowColor: AppColors.secondary.withValues(alpha: 0.3),
              ),
              child: Text('submit'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(String postId, int rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('ratings').add({
      'postId': postId,
      'userId': user.uid,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _reportPost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('report_post'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text('inappropriate_content'.tr()),
              onTap: () => _submitReport(context, postId, 'inappropriate'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: Colors.blue),
              title: Text('spam'.tr()),
              onTap: () => _submitReport(context, postId, 'spam'),
            ),
            ListTile(
              leading: const Icon(Icons.money_off, color: Colors.red),
              title: Text('fraud'.tr()),
              onTap: () => _submitReport(context, postId, 'fraud'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(
    BuildContext context,
    String postId,
    String reason,
  ) async {
    if (!context.mounted) return;
    Navigator.pop(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'postId': postId,
      'reporterId': user.uid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('report_submitted'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    data['userPhoto'] ??
                        'https://ui-avatars.com/api/?background=6C27B0&color=fff&name=User',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'مستخدم',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['timestamp'] != null
                            ? _formatDate(data['timestamp'].toDate())
                            : 'الآن',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'rate') {
                      _showRatingDialog(context, widget.post.id);
                    } else if (value == 'report') {
                      _reportPost(context, widget.post.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rate',
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text('rate_post'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('report_post'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['title'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (data['price'] != null &&
                data['price'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${'price'.tr()}: ${data['price']} ${'egp'.tr()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // عرض الفيديو أو الصور
            if (data['mediaUrls'] != null &&
                (data['mediaUrls'] as List).isNotEmpty) ...[
              if (data['mediaType'] == 'video' &&
                  _videoController != null &&
                  _isVideoInitialized)
                Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                )
              else if (data['mediaType'] == 'image')
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (data['mediaUrls'] as List).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            (data['mediaUrls'] as List)[index],
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                Text('${data['likes']?.length ?? 0}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {},
                ),
                Text('${data['comments'] ?? 0}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _sharePost(data),
                  tooltip: 'share'.tr(),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primary),
                  onPressed: () {
                    _startChat(
                      context,
                      data['userId'],
                      data['userName'] ?? 'مستخدم',
                      data['userPhoto'] ?? '',
                    );
                  },
                  tooltip: 'chat'.tr(),
                ),
                const Spacer(),
                if (data['phone'] != null &&
                    data['phone'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () => _callPhone(data['phone']),
                    tooltip: 'call'.tr(),
                  ),
                if (data['whatsapp'] != null &&
                    data['whatsapp'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.green),
                    onPressed: () => _openWhatsApp(data['whatsapp']),
                    tooltip: 'whatsapp'.tr(),
                  ),
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Colors.amber : null,
                  ),
                  onPressed: _toggleSavePost,
                  tooltip: 'save'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
