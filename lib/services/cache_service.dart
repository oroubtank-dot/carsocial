import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CacheService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  static bool get isAvailable => _isInitialized;

  static Future<void> cacheUser(Map<String, dynamic> userData) async {
    if (!isAvailable) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _prefs?.setString('user_$userId', userData.toString());
    }
  }

  static Map<String, dynamic>? getCachedUser() {
    if (!isAvailable) return null;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    final data = _prefs?.getString('user_$userId');
    return data != null ? {} : null;
  }

  static Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    if (!isAvailable) return;
  }

  static List<Map<String, dynamic>>? getCachedPosts() {
    if (!isAvailable) return null;
    return null;
  }

  static Future<void> clearCache() async {
    if (!isAvailable) return;
    await _prefs?.clear();
  }
}
