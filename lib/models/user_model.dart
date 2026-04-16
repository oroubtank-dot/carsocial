import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final String subscription;
  final DateTime? createdAt;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoURL,
    this.subscription = 'free',
    this.createdAt,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? data['userName'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      subscription: data['subscription'] ?? 'free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      postsCount: data['postsCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
    );
  }
}
