import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadImages(List<XFile> images, String userId) async {
    List<String> imageUrls = [];

    for (var image in images) {
      try {
        final file = File(image.path);
        final fileName =
            'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        if (kDebugMode) {
          print('خطأ في رفع الصورة: $e');
        }
      }
    }

    return imageUrls;
  }

  Future<String?> uploadVideo(File video, String userId) async {
    try {
      final fileName =
          'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(video);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في رفع الفيديو: $e');
      }
      return null;
    }
  }

  Future<String?> uploadProfileImage(File image, String userId) async {
    try {
      final fileName = 'profile/$userId.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في رفع صورة الملف الشخصي: $e');
      }
      return null;
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في حذف الصورة: $e');
      }
    }
  }
}
