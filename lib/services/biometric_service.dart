import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // التحقق من توفر البصمة
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // الحصول على أنواع البصمات المتاحة
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // المصادقة بالبصمة
  static Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  // حفظ حالة تفعيل البصمة
  static Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_$userId', enabled);
  }

  // التحقق من حالة تفعيل البصمة
  static Future<bool> isBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_$userId') ?? false;
  }
}