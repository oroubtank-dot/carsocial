import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../widgets/responsive_service_icons.dart';
import '../constants/app_colors.dart';
import '../utils/toast_helper.dart';
import 'comments_screen.dart';
import 'create_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
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

  // Infinite Scroll variables
  List<QueryDocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isFirstLoad = true;
  final ScrollController _scrollController = ScrollController();

  late final Stream<QuerySnapshot> _storiesStream;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
    _storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true);

      if (_selectedFilter != 'all') {
        query = query.where('serviceKey', isEqualTo: _selectedFilter);
      }

      final snapshot = await query.limit(20).get();

      setState(() {
        _posts = snapshot.docs;
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == 20;
        _isFirstLoad = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل المنشورات: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!);

      if (_selectedFilter != 'all') {
        query = query.where('serviceKey', isEqualTo: _selectedFilter);
      }

      final snapshot = await query.limit(20).get();

      setState(() {
        _posts.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل المزيد: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = [];
      _lastDoc = null;
      _hasMore = true;
      _isFirstLoad = true;
    });
    await _loadPosts();
  }

  void _refreshFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _posts = [];
      _lastDoc = null;
      _hasMore = true;
      _isFirstLoad = true;
    });
    _loadPosts();
  }

  void _showFilterMessage(String label) {
    ToastHelper.showInfo('تم اختيار: $label');
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.onPrimary),
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
                      child: Text('logout'.tr(),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  ToastHelper.showSuccess('تم تسجيل الخروج');
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshPosts,
        child: isWeb
            ? Row(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        _buildSearchBar(isDark),
                        _buildStoriesSection(),
                        _buildCreatePostCard(user, isDark),
                        _buildPostsList(),
                      ],
                    ),
                  ),
                  ResponsiveServiceIcons(
                    selectedFilter: _selectedFilter,
                    onFilterSelected: _refreshFilter,
                    showFilterMessage: _showFilterMessage,
                  ),
                ],
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSearchBar(isDark),
                  _buildHorizontalFilters(),
                  _buildStoriesSection(),
                  _buildCreatePostCard(user, isDark),
                  _buildPostsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return SliverToBoxAdapter(
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
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    int visibleCount = 3;

    if (screenWidth > 600) {
      visibleCount = 5;
    }

    final allServices = _getHorizontalServices();
    final visibleServices = allServices.take(visibleCount).toList();
    final hasMore = allServices.length > visibleCount;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 85,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            ...visibleServices.map((service) => _buildHorizontalIconItem(
                  icon: service['icon'],
                  label: service['label'],
                  color: service['color'],
                  isSelected: _selectedFilter == service['filterKey'],
                  filterKey: service['filterKey'],
                )),
            if (hasMore)
              _buildHorizontalIconItem(
                icon: Icons.more_horiz,
                label: 'more'.tr(),
                color: Colors.grey,
                isSelected: false,
                filterKey: 'more',
                onTap: () => _showMoreServicesDialog(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalIconItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required String filterKey,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ??
          () {
            _refreshFilter(filterKey);
            _showFilterMessage(label);
          },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [color, color.withValues(alpha: 0.8)]
                      : [
                          color.withValues(alpha: 0.1),
                          color.withValues(alpha: 0.05)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SliverToBoxAdapter(
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
    );
  }

  Widget _buildCreatePostCard(User? user, bool isDark) {
    return SliverToBoxAdapter(
      child: Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text('what_to_post'.tr(),
              style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isFirstLoad) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'no_posts'.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _posts.length - 1 && _hasMore) {
          return Column(
            children: [
              _buildPostCard(_posts[index].data() as Map<String, dynamic>,
                  _posts[index].id),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        return _buildPostCard(
            _posts[index].data() as Map<String, dynamic>, _posts[index].id);
      }, childCount: _posts.length),
    );
  }

  Widget _buildAddStoryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _pickAndUploadStory(context),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.white,
                    child: Icon(Icons.add,
                        color: Theme.of(context).primaryColor, size: 30),
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
            Text('your_story'.tr(),
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String name, String photoUrl, String mediaUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black87),
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

  Widget _buildPostCard(Map<String, dynamic> data, String postId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        (data['likes'] as List?)?.contains(currentUser?.uid) ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        data['service'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                  onPressed: () {
                    _showPostOptions(context, postId, data['userId']);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['title'] ?? '',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            if (data['price'] != null &&
                data['price'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'السعر: ${data['price']} ج.م',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
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
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        _showLoginRequiredMessage();
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
                        ToastHelper.showSuccess('تم الإعجاب');
                      }
                    }

                    await postRef.update({'likes': likes});
                  },
                ),
                Text('${(data['likes'] as List?)?.length ?? 0}',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment_outlined,
                      color: isDark ? Colors.white70 : Colors.grey.shade700),
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _showLoginRequiredMessage();
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommentsScreen(postId: postId)),
                    );
                  },
                ),
                Text('${data['comments'] ?? 0}',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: isDark ? Colors.white70 : Colors.grey.shade700),
                  onPressed: () => _showShareOptions(context, data),
                ),
                IconButton(
                  icon: Icon(Icons.bookmark_border,
                      color: isDark ? Colors.white70 : Colors.grey.shade700),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _showLoginRequiredMessage();
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
          ToastHelper.showWarning('تم إزالة من المحفوظات');
        }
      } else {
        await saveRef.set({
          'postId': postId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ToastHelper.showSuccess('تم الحفظ في المفضلة');
        }
      }
    } catch (e) {
      debugPrint('خطأ في حفظ المنشور: $e');
    }
  }

  void _showPostOptions(BuildContext context, String postId, String ownerId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == ownerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
        ),
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
          ToastHelper.showSuccess('تم حذف المنشور بنجاح');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError('حدث خطأ: ${e.toString()}');
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
          ToastHelper.showSuccess('تم الإبلاغ عن المنشور، شكراً لك');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError('حدث خطأ: ${e.toString()}');
        }
      }
    }
  }

  void _showLoginRequiredMessage() {
    ToastHelper.showWarning('يجب تسجيل الدخول أولاً');
  }

  void _showShareOptions(BuildContext context, Map<String, dynamic> postData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
          ),
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
    ToastHelper.showSuccess('تم نسخ الرابط');
  }

  Future<void> _pickAndUploadStory(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredMessage();
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
        ToastHelper.showSuccess('story_added'.tr());
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ToastHelper.showError('خطأ: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ToastHelper.showError('story_failed'.tr());
      }
    }
  }

  void _showMoreServicesDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
          ),
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
                children: _getAllServices().map((service) {
                  return _buildServiceItem(
                    icon: service['icon'],
                    label: service['label'],
                    color: service['color'],
                    filterKey: service['filterKey'],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required String filterKey,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _refreshFilter(filterKey);
        _showFilterMessage(label);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getHorizontalServices() {
    return [
      {
        'icon': Icons.home,
        'label': 'all'.tr(),
        'filterKey': 'all',
        'color': AppColors.primary
      },
      {
        'icon': Icons.directions_car,
        'label': 'cars'.tr(),
        'filterKey': 'cars',
        'color': Colors.blue
      },
      {
        'icon': Icons.build,
        'label': 'workshops'.tr(),
        'filterKey': 'workshops',
        'color': Colors.orange
      },
      {
        'icon': Icons.movie,
        'label': 'films'.tr(),
        'filterKey': 'films',
        'color': Colors.purple
      },
      {
        'icon': Icons.brush,
        'label': 'painting'.tr(),
        'filterKey': 'painting',
        'color': Colors.red
      },
      {
        'icon': Icons.electrical_services,
        'label': 'electric'.tr(),
        'filterKey': 'electric',
        'color': Colors.amber
      },
      {
        'icon': Icons.tire_repair,
        'label': 'tires'.tr(),
        'filterKey': 'tires',
        'color': Colors.brown
      },
      {
        'icon': Icons.handyman,
        'label': 'spare_parts'.tr(),
        'filterKey': 'spare_parts',
        'color': Colors.teal
      },
    ];
  }

  List<Map<String, dynamic>> _getAllServices() {
    return [
      {
        'icon': Icons.home,
        'label': 'الكل',
        'filterKey': 'all',
        'color': AppColors.primary
      },
      {
        'icon': Icons.directions_car,
        'label': 'سيارات',
        'filterKey': 'cars',
        'color': Colors.blue
      },
      {
        'icon': Icons.build,
        'label': 'ورش صيانة',
        'filterKey': 'workshops',
        'color': Colors.orange
      },
      {
        'icon': Icons.movie,
        'label': 'أفلام حماية',
        'filterKey': 'films',
        'color': Colors.purple
      },
      {
        'icon': Icons.brush,
        'label': 'سمكرة ودهان',
        'filterKey': 'painting',
        'color': Colors.red
      },
      {
        'icon': Icons.electrical_services,
        'label': 'كهرباء',
        'filterKey': 'electric',
        'color': Colors.amber
      },
      {
        'icon': Icons.tire_repair,
        'label': 'إطارات',
        'filterKey': 'tires',
        'color': Colors.brown
      },
      {
        'icon': Icons.handyman,
        'label': 'قطع غيار',
        'filterKey': 'spare_parts',
        'color': Colors.teal
      },
      {
        'icon': Icons.brush,
        'label': 'اكسسوارات',
        'filterKey': 'accessories',
        'color': Colors.pink
      },
      {
        'icon': Icons.air,
        'label': 'عادم',
        'filterKey': 'exhaust',
        'color': Colors.grey
      },
      {
        'icon': Icons.settings,
        'label': 'تظبيط',
        'filterKey': 'tuning',
        'color': Colors.indigo
      },
      {
        'icon': Icons.ac_unit,
        'label': 'تكييف',
        'filterKey': 'ac',
        'color': Colors.cyan
      },
      {
        'icon': Icons.shield,
        'label': 'طلاء حماية',
        'filterKey': 'coating',
        'color': Colors.green
      },
      {
        'icon': Icons.description,
        'label': 'رخص',
        'filterKey': 'license',
        'color': Colors.deepPurple
      },
      {
        'icon': Icons.local_shipping,
        'label': 'نقل',
        'filterKey': 'transport',
        'color': Colors.blueGrey
      },
      {
        'icon': Icons.school,
        'label': 'تعليم قيادة',
        'filterKey': 'driving',
        'color': Colors.lime
      },
      {
        'icon': Icons.store,
        'label': 'معارض',
        'filterKey': 'dealership',
        'color': Colors.deepOrange
      },
      {
        'icon': Icons.money,
        'label': 'تمويل',
        'filterKey': 'finance',
        'color': Colors.green.shade700
      },
      {
        'icon': Icons.security,
        'label': 'تأمين',
        'filterKey': 'insurance',
        'color': Colors.blue.shade700
      },
    ];
  }
}
