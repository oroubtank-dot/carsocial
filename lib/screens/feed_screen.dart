import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../widgets/filter_chip.dart';
import 'comments_screen.dart';
import 'create_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../services/cache_service.dart';
import '../services/points_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ImagePicker _storyPicker = ImagePicker();
  String _selectedFilter = 'all';
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final Map<String, String> _filterMap = {
    'all': 'all',
    'cars': 'سيارات',
    'workshops': 'ورش صيانة',
    'inspection': 'مراكز فحص',
    'films': 'أفلام حماية',
    'painting': 'سمكرة ودهان',
    'electric': 'كهرباء سيارات',
    'tires': 'إطارات',
    'spare_parts': 'قطع غيار',
  };

  late final Stream<QuerySnapshot> _postsStream;
  late final Stream<QuerySnapshot> _storiesStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _getPostsStream();
    _storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Stream<QuerySnapshot> _getPostsStream() {
    var query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'all') {
      final serviceName = _filterMap[_selectedFilter] ?? '';
      if (serviceName.isNotEmpty) {
        query = query.where('service', isEqualTo: serviceName);
      }
    }

    return query.snapshots();
  }

  Future<void> _sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('خطأ في إرسال الإشعار: $e');
    }
  }

  bool _isValidPost(Map<String, dynamic> data) {
    return data['title'] != null &&
        data['title'].toString().length <= 100 &&
        data['description'] != null &&
        data['description'].toString().length <= 1000 &&
        (data['price'] == null || data['price'].toString().length <= 20);
  }

  Future<void> _refreshData() async {
    setState(() {
      _postsStream = _getPostsStream();
      _storiesStream = FirebaseFirestore.instance
          .collection('stories')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('createdAt', descending: true)
          .snapshots();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        centerTitle: true,
        actions: [
          // أيقونة المفضلة (جديدة)
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onThemeChanged: (isDarkMode) {},
                    currentTheme:
                        Theme.of(context).brightness == Brightness.dark,
                    onLanguageChanged: (locale) {
                      context.setLocale(locale);
                    },
                    currentLocale: context.locale,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('logout'.tr()),
                  content: Text('logout_confirmation'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'logout'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 85,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    FilterChipWidget(
                      icon: Icons.home,
                      label: 'all'.tr(),
                      isSelected: _selectedFilter == 'all',
                      onTap: () {
                        setState(() => _selectedFilter = 'all');
                        _showFilterMessage(context, 'all'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.directions_car,
                      label: 'cars'.tr(),
                      isSelected: _selectedFilter == 'cars',
                      onTap: () {
                        setState(() => _selectedFilter = 'cars');
                        _showFilterMessage(context, 'cars'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.build,
                      label: 'workshops'.tr(),
                      isSelected: _selectedFilter == 'workshops',
                      onTap: () {
                        setState(() => _selectedFilter = 'workshops');
                        _showFilterMessage(context, 'workshops'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.search,
                      label: 'inspection'.tr(),
                      isSelected: _selectedFilter == 'inspection',
                      onTap: () {
                        setState(() => _selectedFilter = 'inspection');
                        _showFilterMessage(context, 'inspection'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.movie,
                      label: 'films'.tr(),
                      isSelected: _selectedFilter == 'films',
                      onTap: () {
                        setState(() => _selectedFilter = 'films');
                        _showFilterMessage(context, 'films'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.brush,
                      label: 'painting'.tr(),
                      isSelected: _selectedFilter == 'painting',
                      onTap: () {
                        setState(() => _selectedFilter = 'painting');
                        _showFilterMessage(context, 'painting'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.electrical_services,
                      label: 'electric'.tr(),
                      isSelected: _selectedFilter == 'electric',
                      onTap: () {
                        setState(() => _selectedFilter = 'electric');
                        _showFilterMessage(context, 'electric'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.tire_repair,
                      label: 'tires'.tr(),
                      isSelected: _selectedFilter == 'tires',
                      onTap: () {
                        setState(() => _selectedFilter = 'tires');
                        _showFilterMessage(context, 'tires'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.handyman,
                      label: 'spare_parts'.tr(),
                      isSelected: _selectedFilter == 'spare_parts',
                      onTap: () {
                        setState(() => _selectedFilter = 'spare_parts');
                        _showFilterMessage(context, 'spare_parts'.tr());
                      },
                    ),
                    FilterChipWidget(
                      icon: Icons.more_horiz,
                      label: 'more'.tr(),
                      isSelected: false,
                      onTap: () => _showMoreServices(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _storiesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildAddStoryCard(),
                        if (snapshot.hasData && snapshot.data != null)
                          ...snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildStoryCard(
                              data['userName'] ?? 'مستخدم',
                              data['userPhoto'] ?? '',
                              data['mediaUrl'] ?? '',
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0A2E5C),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('what_to_post'.tr(),
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateScreen()),
                    );
                  },
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('حدث خطأ: ${snapshot.error}')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final posts = snapshot.data?.docs ?? [];

                // حفظ المنشورات في الكاش
                if (posts.isNotEmpty) {
                  final postsData = posts.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'data': data,
                    };
                  }).toList();
                  CacheService.cachePosts(
                      postsData.cast<Map<String, dynamic>>());
                }

                if (posts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'no_posts'.tr(),
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    final data = post.data() as Map<String, dynamic>;

                    if (!_isValidPost(data)) {
                      return const SizedBox.shrink();
                    }

                    return _buildPostCard(data, post.id, context);
                  }, childCount: posts.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryCard() {
    return GestureDetector(
      onTap: () => _pickAndUploadStory(context),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add, color: Color(0xFF0A2E5C), size: 30),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A2E5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('your_story'.tr(), style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String name, String photoUrl, String mediaUrl) {
    return GestureDetector(
      onTap: () {
        _showStoryViewer(mediaUrl);
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(35),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black54),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(String mediaUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('تعذر تحميل القصة',
                          style: TextStyle(color: Colors.white)),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(
      Map<String, dynamic> data, String postId, BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        (data['likes'] as List?)?.contains(currentUser?.uid) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0A2E5C),
                  backgroundImage:
                      data['userPhoto'] != null && data['userPhoto'].isNotEmpty
                          ? NetworkImage(data['userPhoto'])
                          : null,
                  child: data['userPhoto'] == null || data['userPhoto'].isEmpty
                      ? Text(
                          data['userName']?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'مستخدم',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        data['service'] ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showPostOptions(context, postId, data['userId']);
                  },
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
                'السعر: ${data['price']} ج.م',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E5C)),
              ),
            ],
            if (data['mediaUrls'] != null &&
                (data['mediaUrls'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey, size: 50),
                            );
                          },
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
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      if (mounted) {
                        _showLoginRequiredMessage(context);
                      }
                      return;
                    }

                    final postRef = FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId);
                    final likes = List<String>.from(data['likes'] ?? []);

                    if (likes.contains(user.uid)) {
                      likes.remove(user.uid);
                    } else {
                      likes.add(user.uid);
                      if (data['userId'] != user.uid) {
                        await _sendNotification(
                          userId: data['userId'],
                          type: 'like',
                          title: 'إعجاب جديد',
                          body: '${user.displayName ?? 'مستخدم'} أعجب بمنشورك',
                        );
                        await PointsService.addPoints(
                            data['userId'], 1, 'تم الإعجاب بمنشورك');
                      }
                    }

                    await postRef.update({'likes': likes});
                  },
                ),
                Text('${(data['likes'] as List?)?.length ?? 0}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _showLoginRequiredMessage(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommentsScreen(postId: postId)),
                    );
                  },
                ),
                Text('${data['comments'] ?? 0}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _showShareOptions(context, data),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _showLoginRequiredMessage(context);
                      return;
                    }
                    await _toggleSavePost(postId, user.uid);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSavePost(String postId, String userId) async {
    try {
      final saveRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId);

      final doc = await saveRef.get();

      if (doc.exists) {
        await saveRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم إزالة من المحفوظات'),
                duration: Duration(seconds: 1)),
          );
        }
      } else {
        await saveRef.set({
          'postId': postId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم الحفظ'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في حفظ المنشور: $e');
    }
  }

  void _showPostOptions(BuildContext context, String postId, String ownerId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == ownerId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('تعديل المنشور'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف المنشور'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(postId);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: const Text('الإبلاغ عن منشور'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(postId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: const Text('هل أنت متأكد من حذف هذا المنشور؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم حذف المنشور بنجاح'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _reportPost(String postId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإبلاغ عن منشور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لماذا تريد الإبلاغ عن هذا المنشور؟'),
            const SizedBox(height: 16),
            ...[
              'محتوى غير لائق',
              'عنف أو كراهية',
              'انتحال شخصية',
              'مخالف للقوانين'
            ].map((r) => ListTile(
                  title: Text(r),
                  onTap: () => Navigator.pop(context, r),
                )),
          ],
        ),
      ),
    );

    if (reason != null && mounted) {
      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'postId': postId,
          'reason': reason,
          'reportedBy': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم الإبلاغ عن المنشور، شكراً لك'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showLoginRequiredMessage(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('login_required'.tr()),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'تسجيل الدخول'.tr(),
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('share'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.share, color: Colors.green),
                ),
                title: Text('share_external'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _shareExternal(postData);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.link, color: Colors.grey),
                ),
                title: Text('copy_link'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _copyLink(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareExternal(Map<String, dynamic> postData) {
    final title = postData['title'] ?? 'CarSocial Post';
    final description = postData['description'] ?? '';
    final price = postData['price'] ?? '';

    final text = '''
🚗 *$title*
📝 $description
${price.isNotEmpty ? '💰 السعر: $price ج.م\n' : ''}
📱 حمّل تطبيق CarSocial لمشاهدة المزيد!
''';

    Share.share(text);
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(
        const ClipboardData(text: 'https://carsocial.app/post/123'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('link_copied'.tr()), backgroundColor: Colors.green),
    );
  }

  Future<void> _pickAndUploadStory(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredMessage(context);
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Color(0xFF0A2E5C)),
            title: Text('choose_images'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final image =
                  await _storyPicker.pickImage(source: ImageSource.gallery);
              if (image != null && mounted) {
                await _uploadStory(File(image.path), 'image');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Color(0xFFFF6B00)),
            title: Text('choose_video'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final video =
                  await _storyPicker.pickVideo(source: ImageSource.gallery);
              if (video != null && mounted) {
                await _uploadStory(File(video.path), 'video');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadStory(File file, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final ref = FirebaseStorage.instance.ref().child(
            'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.${type == 'image' ? 'jpg' : 'mp4'}',
          );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'مستخدم',
        'userPhoto': user.photoURL ?? '',
        'mediaUrl': url,
        'mediaType': type,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('story_added'.tr()), backgroundColor: Colors.green),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        String message;
        switch (e.code) {
          case 'storage/unauthorized':
            message = 'غير مصرح لك برفع الملفات';
            break;
          case 'storage/canceled':
            message = 'تم إلغاء الرفع';
            break;
          case 'storage/quota-exceeded':
            message = 'تم تجاوز مساحة التخزين';
            break;
          default:
            message = 'حدث خطأ: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${'story_failed'.tr()}: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFilterMessage(BuildContext context, String filterName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${'selected'.tr()}: $filterName'),
          duration: const Duration(seconds: 1)),
    );
  }

  void _showMoreServices(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('more_services'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildServiceItem(
                      Icons.brush, 'accessories'.tr(), Colors.purple),
                  _buildServiceItem(Icons.air, 'exhaust'.tr(), Colors.brown),
                  _buildServiceItem(
                      Icons.settings, 'tuning'.tr(), Colors.orange),
                  _buildServiceItem(Icons.ac_unit, 'ac'.tr(), Colors.cyan),
                  _buildServiceItem(Icons.shield, 'coating'.tr(), Colors.green),
                  _buildServiceItem(
                      Icons.description, 'license'.tr(), Colors.indigo),
                  _buildServiceItem(
                      Icons.local_shipping, 'transport'.tr(), Colors.blueGrey),
                  _buildServiceItem(Icons.school, 'driving'.tr(), Colors.teal),
                  _buildServiceItem(Icons.store, 'dealership'.tr(), Colors.red),
                  _buildServiceItem(
                      Icons.money, 'finance'.tr(), const Color(0xFF2E7D32)),
                  _buildServiceItem(Icons.security, 'insurance'.tr(),
                      const Color(0xFF1565C0)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    final Color colorWithAlpha = color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedFilter = label;
        });
        _showFilterMessage(context, label);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: colorWithAlpha, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
