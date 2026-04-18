import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب أول 20 منشور
  Future<List<PostModel>> getPosts({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // جلب الدفعة التالية (بعد آخر منشور)
  Future<List<PostModel>> getMorePosts(DocumentSnapshot lastDoc,
      {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }
}
