import 'package:flutter/material.dart';

class OtherProfileScreen extends StatelessWidget {
  const OtherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'بروفايل مستخدم آخر',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}