import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WantedScreen extends StatefulWidget {
  const WantedScreen({super.key});

  @override
  State<WantedScreen> createState() => _WantedScreenState();
}

class _WantedScreenState extends State<WantedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  Future<void> _addWantedRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('wanted').add({
      'carName': _carNameController.text,
      'maxPrice': int.tryParse(_maxPriceController.text) ?? 0,
      'area': _areaController.text,
      'userId': user.uid,
      'userName': user.displayName ?? user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة طلب الشراء بنجاح')),
      );
    }
  }

  void _showAddWantedDialog() {
    _carNameController.clear();
    _maxPriceController.clear();
    _areaController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة طلب شراء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _carNameController,
              decoration: const InputDecoration(labelText: 'السيارة المطلوبة'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الحد الأقصى للسعر'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'المنطقة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _addWantedRequest();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مطلوب'),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('wanted')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final wants = snapshot.data!.docs;
          if (wants.isEmpty) {
            return const Center(child: Text('لا توجد طلبات شراء حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: wants.length,
            itemBuilder: (context, index) {
              final want = wants[index];
              final data = want.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              data['userName']?[0]?.toUpperCase() ?? 'U',
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
                                  ),
                                ),
                                Text(
                                  data['carName'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Color(0xFFFF6B00),
                          ),
                          const SizedBox(width: 4),
                          Text('الحد الأقصى: ${data['maxPrice']} ج.م'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(data['area'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.message),
                              label: const Text('اتصل بالبائع'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWantedDialog,
        backgroundColor: const Color(0xFFFF6B00),
        child: const Icon(Icons.add),
      ),
    );
  }
}
