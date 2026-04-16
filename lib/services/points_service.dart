import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة نقاط للمستخدم
  static Future<void> addPoints(
      String userId, int points, String reason) async {
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final currentPoints = snapshot.data()?['points'] ?? 0;

      final newPoints = currentPoints + points;
      final newLevel = _calculateLevel(newPoints);

      transaction.update(userRef, {
        'points': newPoints,
        'level': newLevel,
        'lastActivity': FieldValue.serverTimestamp(),
      });
    });

    // تسجيل سبب النقاط
    await _firestore.collection('points_history').add({
      'userId': userId,
      'points': points,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static int _calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    if (points < 2100) return 6;
    if (points < 2800) return 7;
    if (points < 3600) return 8;
    if (points < 4500) return 9;
    return 10;
  }

  // الحصول على مكافأة الـ Level
  static String getLevelBadge(int level) {
    switch (level) {
      case 1:
        return '🟢 مبتدئ';
      case 2:
        return '🔵 فضّي';
      case 3:
        return '🔵 فضّي متقدم';
      case 4:
        return '🟡 ذهبي';
      case 5:
        return '🟡 ذهبي متقدم';
      case 6:
        return '🟣 بلاتيني';
      case 7:
        return '🟣 بلاتيني متقدم';
      case 8:
        return '🔴 ماسي';
      case 9:
        return '🔴 ماسي متقدم';
      case 10:
        return '👑 أسطوري';
      default:
        return '🟢 مبتدئ';
    }
  }

  // الحصول على لون الشارة حسب الـ Level
  static Color getLevelColor(int level) {
    if (level < 3) return Colors.green;
    if (level < 5) return Colors.blue;
    if (level < 7) return Colors.amber;
    if (level < 9) return Colors.purple;
    return Colors.red;
  }

  // الحصول على نقاط المستخدم الحالي
  static Future<Map<String, dynamic>> getUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'points': 0, 'level': 1};

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return {
      'points': doc.data()?['points'] ?? 0,
      'level': doc.data()?['level'] ?? 1,
    };
  }
}
