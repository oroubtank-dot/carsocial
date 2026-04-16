import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _postsCount = 0;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // عدد المنشورات
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();
      _postsCount = postsSnapshot.docs.length;

      // عدد الإعجابات والكومنتات
      int totalLikes = 0;
      int totalComments = 0;
      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        final likes = data['likes'] as List?;
        totalLikes += likes?.length ?? 0;
        totalComments += (data['comments'] as int?) ?? 0;
      }
      _likesCount = totalLikes;
      _commentsCount = totalComments;

      // عدد المتابعين والمتابعة
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      _followersCount = (userData?['followersCount'] as int?) ?? 0;
      _followingCount = (userData?['followingCount'] as int?) ?? 0;
    } catch (e) {
      debugPrint('خطأ في تحميل الإحصائيات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('stats'.tr()), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard(
                    icon: Icons.post_add,
                    title: 'posts'.tr(),
                    value: _postsCount,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.favorite,
                    title: 'likes'.tr(),
                    value: _likesCount,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.comment,
                    title: 'comments'.tr(),
                    value: _commentsCount,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.people,
                    title: 'followers'.tr(),
                    value: _followersCount,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.person_add,
                    title: 'following'.tr(),
                    value: _followingCount,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
