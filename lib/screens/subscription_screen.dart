import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentSubscription = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (mounted) {
      setState(() {
        _currentSubscription = userDoc.data()?['subscription'] ?? 'free';
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeToSilver() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'subscription': 'silver',
      'subscriptionExpiry': DateTime.now().add(const Duration(days: 30)),
    });

    if (mounted) {
      setState(() {
        _currentSubscription = 'silver';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الترقية إلى الباقة الفضية!')),
      );
    }
  }

  Future<void> _upgradeToGold() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'subscription': 'gold',
      'subscriptionExpiry': DateTime.now().add(const Duration(days: 30)),
    });

    if (mounted) {
      setState(() {
        _currentSubscription = 'gold';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الترقية إلى الباقة الذهبية!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراكات'),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentSubscription != 'free')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentSubscription == 'gold'
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentSubscription == 'gold'
                          ? Icons.star
                          : Icons.star_half,
                      color: _currentSubscription == 'gold'
                          ? const Color(0xFFFFD700)
                          : Colors.grey,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _currentSubscription == 'gold'
                            ? 'أنت مشترك في الباقة الذهبية'
                            : 'أنت مشترك في الباقة الفضية',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'اختر الباقة المناسبة لك',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'مميزات الاشتراك:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• بوستات غير محدودة'),
            const Text('• علامة مميزة على البروفايل'),
            const Text('• تثبيت البوستات'),
            const Text('• ظهور متقدم في البحث'),
            const SizedBox(height: 24),

            // الباقة الفضية
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.star_half, size: 50, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'الباقة الفضية',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '199 ج.م / شهر',
                      style: TextStyle(fontSize: 18, color: Color(0xFFFF6B00)),
                    ),
                    const SizedBox(height: 16),
                    const Text('✓ علامة فضية'),
                    const Text('✓ تثبيت بوست واحد'),
                    const Text('✓ ظهور متقدم في البحث'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _currentSubscription == 'silver'
                            ? null
                            : _upgradeToSilver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentSubscription == 'silver'
                              ? Colors.grey
                              : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentSubscription == 'silver'
                              ? 'مشترك حالياً'
                              : 'اشتراك 199 ج.م',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الباقة الذهبية
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFF4A460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 50,
                        color: Color(0xFFFFD700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'الباقة الذهبية',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '499 ج.م / شهر',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '✓ علامة ذهبية',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Text(
                        '✓ تثبيت 3 بوستات',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Text(
                        '✓ ظهور أول في البحث',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Text(
                        '✓ إحصائيات متقدمة',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _currentSubscription == 'gold'
                              ? null
                              : _upgradeToGold,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF6B00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentSubscription == 'gold'
                                ? 'مشترك حالياً'
                                : 'اشتراك 499 ج.م',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
