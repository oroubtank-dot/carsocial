import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String title;
  final String description;
  final String service;
  final String serviceKey;
  final String? price;
  final List<String> mediaUrls;
  final String mediaType;
  final List<String> likes;
  final int comments;
  final String? phone;
  final String? whatsapp;
  final String? condition;
  final bool negotiable;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.title,
    required this.description,
    required this.service,
    required this.serviceKey,
    this.price,
    required this.mediaUrls,
    required this.mediaType,
    required this.likes,
    required this.comments,
    this.phone,
    this.whatsapp,
    this.condition,
    required this.negotiable,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'مستخدم',
      userPhoto: data['userPhoto'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      service: data['service'] ?? '',
      serviceKey: data['serviceKey'] ?? '',
      price: data['price'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: data['mediaType'] ?? 'image',
      likes: List<String>.from(data['likes'] ?? []),
      comments: data['comments'] ?? 0,
      phone: data['phone'],
      whatsapp: data['whatsapp'],
      condition: data['condition'],
      negotiable: data['negotiable'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
