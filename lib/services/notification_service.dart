import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> sendNotification({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    String? postId,
  }) async {
    final fromUser = _auth.currentUser;
    if (fromUser == null) return;

    await _firestore.collection('notifications').add({
      'userId': toUserId,
      'fromId': fromUser.uid,
      'fromName': fromUser.displayName ?? 'مستخدم',
      'type': type,
      'title': title,
      'body': body,
      'postId': postId,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendLikeNotification({
    required String toUserId,
    required String postId,
  }) async {
    await sendNotification(
      toUserId: toUserId,
      type: 'like',
      title: 'إعجاب جديد',
      body: 'أعجب ${_auth.currentUser?.displayName ?? 'مستخدم'} بمنشورك',
      postId: postId,
    );
  }

  static Future<void> sendCommentNotification({
    required String toUserId,
    required String postId,
    required String comment,
  }) async {
    await sendNotification(
      toUserId: toUserId,
      type: 'comment',
      title: 'تعليق جديد',
      body: 'علق ${_auth.currentUser?.displayName ?? 'مستخدم'}: "$comment"',
      postId: postId,
    );
  }

  static Future<void> sendFollowNotification(String toUserId) async {
    await sendNotification(
      toUserId: toUserId,
      type: 'follow',
      title: 'متابع جديد',
      body: 'بدأ ${_auth.currentUser?.displayName ?? 'مستخدم'} بمتابعتك',
    );
  }
  static Future<void> addPoints(String userId, int points) async {
  await _firestore.collection('users').doc(userId).update({
    'points': FieldValue.increment(points),
  });
}
}