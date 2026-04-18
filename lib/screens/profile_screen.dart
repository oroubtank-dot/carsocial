import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/points_service.dart';
import '../constants/app_colors.dart';
import '../utils/toast_helper.dart';
import 'login_screen.dart';
import 'followers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  String _displayName = '';
  String _email = '';
  String _photoURL = '';
  String _phoneNumber = '';
  DateTime? _creationTime;
  int _points = 0;
  int _level = 1;
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPoints();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      setState(() {
        _displayName = _user!.displayName ?? '';
        _email = _user!.email ?? '';
        _photoURL = _user!.photoURL ?? '';
        _phoneNumber = _user!.phoneNumber ?? '';
        _creationTime = _user!.metadata.creationTime;
      });
    }
  }

  Future<void> _loadPoints() async {
    final pointsData = await PointsService.getUserPoints();
    if (mounted) {
      setState(() {
        _points = pointsData['points'];
        _level = pointsData['level'];
      });
    }
  }

  Future<void> _loadStats() async {
    if (_user == null) return;

    final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: _user!.uid)
        .get();
    _postsCount = postsSnapshot.docs.length;

    final followersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('followers')
        .get();
    _followersCount = followersSnapshot.docs.length;

    final followingSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('following')
        .get();
    _followingCount = followingSnapshot.docs.length;

    setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUploading = true;
      });

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images/${_user!.uid}.jpg');
        await ref.putFile(_imageFile!);
        final downloadUrl = await ref.getDownloadURL();

        await _user!.updatePhotoURL(downloadUrl);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'photoURL': downloadUrl});

        setState(() {
          _photoURL = downloadUrl;
        });

        if (mounted) {
          ToastHelper.showSuccess('تم تحديث الصورة بنجاح');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError('حدث خطأ: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ToastHelper.showSuccess('تم تسجيل الخروج');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError('خطأ في تسجيل الخروج: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatButton(String label, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('profile'.tr()),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('يجب تسجيل الدخول أولاً'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.edit,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserData();
                await _loadPoints();
                await _loadStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_photoURL.isNotEmpty
                                    ? NetworkImage(_photoURL)
                                    : null) as ImageProvider?,
                            child: (_imageFile == null && _photoURL.isEmpty)
                                ? Icon(Icons.person,
                                    size: 60, color: Colors.grey.shade400)
                                : null,
                          ),
                          if (!_isUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (_isUploading)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _displayName.isEmpty ? 'user'.tr() : _displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (_phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // الإحصائيات (المنشورات - المتابعون - يتابعهم)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatButton('posts'.tr(), _postsCount),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersScreen(
                                  userId: _user!.uid,
                                  userName: _displayName,
                                  userPhoto: _photoURL,
                                  initialTab: 'followers',
                                ),
                              ),
                            );
                          },
                          child: _buildStatButton(
                              'followers'.tr(), _followersCount),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersScreen(
                                  userId: _user!.uid,
                                  userName: _displayName,
                                  userPhoto: _photoURL,
                                  initialTab: 'following',
                                ),
                              ),
                            );
                          },
                          child: _buildStatButton(
                              'following'.tr(), _followingCount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // بطاقة النقاط والمستوى
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PointsService.getLevelColor(_level),
                            PointsService.getLevelColor(_level)
                                .withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: PointsService.getLevelColor(_level)
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$_level',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: PointsService.getLevelColor(_level),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PointsService.getLevelBadge(_level),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_points نقطة',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (_points % 100) / 100,
                                    backgroundColor: Colors.white30,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_points % 100}/100 نقطة للمستوى التالي',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بطاقة معلومات الحساب
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.email,
                                color: Theme.of(context).primaryColor),
                            title: Text('email'.tr()),
                            subtitle: Text(_email),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.calendar_today,
                                color: Theme.of(context).primaryColor),
                            title: Text('join_date'.tr()),
                            subtitle: Text(_creationTime != null
                                ? '${_creationTime!.day}/${_creationTime!.month}/${_creationTime!.year}'
                                : ''),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.card_membership,
                                color: Theme.of(context).primaryColor),
                            title: Text('account_type'.tr()),
                            subtitle: Text('free'.tr()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: Text('logout'.tr(),
                              style: const TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
