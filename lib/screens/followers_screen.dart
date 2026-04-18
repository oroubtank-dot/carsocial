import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../utils/toast_helper.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhoto;
  final String initialTab;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    this.initialTab = 'followers',
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'followers' ? 0 : 1,
    );
    _loadCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    final followersSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .get();

    final followingSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .get();

    setState(() {
      _followersCount = followersSnapshot.docs.length;
      _followingCount = followingSnapshot.docs.length;
      _isLoading = false;
    });
  }

  Future<void> _followUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ToastHelper.showWarning('login_required'.tr());
      return;
    }

    if (currentUser.uid == targetUserId) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid)
          .set({
        'userId': currentUser.uid,
        'followedAt': FieldValue.serverTimestamp(),
      });

      ToastHelper.showSuccess('follow_success'.tr());
      setState(() {});
    } catch (e) {
      ToastHelper.showError('error_occurred'.tr());
    }
  }

  Future<void> _unfollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId)
          .delete();

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid)
          .delete();

      ToastHelper.showWarning('unfollow_success'.tr());
      setState(() {});
    } catch (e) {
      ToastHelper.showError('error_occurred'.tr());
    }
  }

  Future<bool> _isFollowing(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: '${'followers'.tr()} ($_followersCount)'),
                      Tab(text: '${'following'.tr()} ($_followingCount)'),
                    ],
                    indicatorColor: AppColors.secondary,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFollowersList(),
                      _buildFollowingList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFollowersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final followers = snapshot.data!.docs;

        if (followers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('no_followers'.tr()),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final follower = followers[index];
            final followerId = follower['userId'];
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(followerId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final currentUser = _auth.currentUser;

                return FutureBuilder<bool>(
                  future: _isFollowing(followerId),
                  builder: (context, followingSnapshot) {
                    final isFollowing = followingSnapshot.data ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userData['photoURL'] != null
                            ? NetworkImage(userData['photoURL'])
                            : null,
                        child: userData['photoURL'] == null
                            ? Text(userData['displayName']?[0]?.toUpperCase() ??
                                'U')
                            : null,
                      ),
                      title: Text(
                        userData['displayName'] ?? 'user'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(userData['email'] ?? ''),
                      trailing: currentUser != null &&
                              currentUser.uid != followerId
                          ? ElevatedButton(
                              onPressed: () {
                                if (isFollowing) {
                                  _unfollowUser(followerId);
                                } else {
                                  _followUser(followerId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.grey
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(isFollowing
                                  ? 'unfollow'.tr()
                                  : 'follow'.tr()),
                            )
                          : null,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .orderBy('followedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final following = snapshot.data!.docs;

        if (following.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('no_following'.tr()),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: following.length,
          itemBuilder: (context, index) {
            final follow = following[index];
            final followId = follow['userId'];
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(followId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final currentUser = _auth.currentUser;

                return FutureBuilder<bool>(
                  future: _isFollowing(followId),
                  builder: (context, followingSnapshot) {
                    final isFollowing = followingSnapshot.data ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userData['photoURL'] != null
                            ? NetworkImage(userData['photoURL'])
                            : null,
                        child: userData['photoURL'] == null
                            ? Text(userData['displayName']?[0]?.toUpperCase() ??
                                'U')
                            : null,
                      ),
                      title: Text(
                        userData['displayName'] ?? 'user'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(userData['email'] ?? ''),
                      trailing: currentUser != null &&
                              currentUser.uid != followId
                          ? ElevatedButton(
                              onPressed: () {
                                if (isFollowing) {
                                  _unfollowUser(followId);
                                } else {
                                  _followUser(followId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.grey
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(isFollowing
                                  ? 'unfollow'.tr()
                                  : 'follow'.tr()),
                            )
                          : null,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
