import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  // تسجيل الدخول
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // إنشاء حساب
  Future<void> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(name);
      
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'followersCount': 0,
        'followingCount': 0,
      });
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'المستخدم غير موجود';
        case 'wrong-password':
          return 'كلمة المرور خاطئة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح';
        default:
          return e.message ?? 'حدث خطأ ما';
      }
    }
    return 'حدث خطأ ما';
  }
}