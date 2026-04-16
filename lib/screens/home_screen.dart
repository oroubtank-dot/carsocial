import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/story_card.dart';
import '../widgets/custom_navbar.dart';
import '../constants/app_colors.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'add_post_screen.dart';
import 'feed_screen.dart';
import 'create_screen.dart';
import 'services_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      const NotificationsScreen(),
      const CreateScreen(),
      const ServicesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  Widget _buildFilterIcon(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isDark ? Colors.grey.shade300 : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
      BuildContext context, IconData icon, String label, Color color) {
    final Color colorWithAlpha = color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'selected'.tr()}: $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorWithAlpha,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _showFilterMessage(BuildContext context, String filterName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'selected'.tr()}: $filterName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreServices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'more_services'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildServiceItem(
                      context, Icons.brush, 'accessories'.tr(), Colors.purple),
                  _buildServiceItem(
                      context, Icons.air, 'exhaust'.tr(), Colors.brown),
                  _buildServiceItem(
                      context, Icons.settings, 'tuning'.tr(), Colors.orange),
                  _buildServiceItem(
                      context, Icons.ac_unit, 'ac'.tr(), Colors.cyan),
                  _buildServiceItem(
                      context, Icons.shield, 'coating'.tr(), Colors.green),
                  _buildServiceItem(context, Icons.description, 'license'.tr(),
                      Colors.indigo),
                  _buildServiceItem(context, Icons.local_shipping,
                      'transport'.tr(), Colors.blueGrey),
                  _buildServiceItem(
                      context, Icons.school, 'driving'.tr(), Colors.teal),
                  _buildServiceItem(
                      context, Icons.store, 'dealership'.tr(), Colors.red),
                  _buildServiceItem(context, Icons.money, 'finance'.tr(),
                      Colors.green.shade700),
                  _buildServiceItem(context, Icons.security, 'insurance'.tr(),
                      Colors.blue.shade700),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('app_name'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
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
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'all'.tr()),
                      child: _buildFilterIcon(context, Icons.home, 'all'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'cars'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.directions_car, 'cars'.tr()),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showFilterMessage(context, 'workshops'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.build, 'workshops'.tr()),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showFilterMessage(context, 'inspection'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.search, 'inspection'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'films'.tr()),
                      child:
                          _buildFilterIcon(context, Icons.movie, 'films'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'painting'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.brush, 'painting'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'electric'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.electrical_services, 'electric'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMessage(context, 'tires'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.tire_repair, 'tires'.tr()),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showFilterMessage(context, 'spare_parts'.tr()),
                      child: _buildFilterIcon(
                          context, Icons.handyman, 'spare_parts'.tr()),
                    ),
                    GestureDetector(
                      onTap: () => _showMoreServices(context),
                      child: _buildFilterIcon(
                          context, Icons.more_horiz, 'more'.tr()),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .where('expiresAt', isGreaterThan: Timestamp.now())
                      .orderBy('expiresAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        StoryCard(
                          isAddStory: true,
                          userId: auth.currentUser?.uid,
                          userName: auth.currentUser?.displayName,
                          userPhoto: auth.currentUser?.photoURL,
                        ),
                        if (snapshot.hasData)
                          ...snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return StoryCard(
                              isAddStory: false,
                              userId: data['userId'],
                              userName: data['userName'],
                              userPhoto: data['userPhoto'],
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      auth.currentUser?.photoURL ??
                          'https://ui-avatars.com/api/?background=6C27B0&color=fff&name=User',
                    ),
                  ),
                  title: Text(
                    'what_to_post'.tr(),
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey),
                  ),
                  onTap: isGuest
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('login_required'.tr())),
                          );
                        }
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddPostScreen()),
                          ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getPosts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('error_occurred'.tr())),
                  );
                }

                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('no_posts'.tr())),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(post: posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
