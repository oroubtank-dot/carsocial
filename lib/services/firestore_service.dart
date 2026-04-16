import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addPost(Map<String, dynamic> postData) async {
    await _firestore.collection('posts').add({
      ...postData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPostWithImages(Map<String, dynamic> postData, List<File> images) async {
    // رفع الصور أولاً
    List<String> imageUrls = [];
    
    for (File image in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.hashCode}.jpg';
      final ref = _storage.ref().child('posts/$fileName');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    // إضافة البوست مع روابط الصور
    await _firestore.collection('posts').add({
      ...postData,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _firestore.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }
}