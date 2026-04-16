import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _keyLanguage = 'app_language';
  
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'ar';
  }
  
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }
  
  static String translate(String arText, String enText) {
    // هتتصل بشكل synchronous من خلال StatefulWidget
    return arText; // هنتحكم فيها من الشاشة نفسها
  }
}