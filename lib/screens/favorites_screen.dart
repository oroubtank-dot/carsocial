import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'البوستات المحفوظة',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}