import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool currentTheme;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.currentTheme;
    _currentLanguage = widget.currentLocale.languageCode == 'ar'
        ? 'العربية'
        : 'English';
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    widget.onThemeChanged(value);
  }

  void _changeLanguage(String language) {
    setState(() {
      _currentLanguage = language;
    });
    final locale = language == 'العربية'
        ? const Locale('ar')
        : const Locale('en');
    widget.onLanguageChanged(locale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('language_changed'.tr()),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLanguageDialog() {
    final isArabic = _currentLanguage == 'العربية';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('select_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('arabic'.tr()),
                leading: isArabic
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  _changeLanguage('العربية');
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: Text('english'.tr()),
                leading: !isArabic
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  _changeLanguage('English');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('privacy_policy'.tr()),
        content: SingleChildScrollView(
          child: Text(
            context.locale.languageCode == 'ar'
                ? 'مسؤولية المستخدم: أنت وحدك المسؤول عن المحتوى الذي تنشره.\n\n'
                      'دورنا كمنصة: CarSocial يعمل كمنصة وسيطة فقط.\n\n'
                      'حدود المسؤولية: لا تتحمل CarSocial أي مسؤولية عن أي أضرار.\n\n'
                      'الأمان وحفظ البيانات: نحن نتخذ إجراءات أمنية معقولة.'
                : 'User Responsibility: You are solely responsible for your content.\n\n'
                      'Our Role: CarSocial acts only as an intermediary platform.\n\n'
                      'Limitation of Liability: CarSocial is not liable for any damages.\n\n'
                      'Security: We take reasonable security measures.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('terms_of_service'.tr()),
        content: SingleChildScrollView(
          child: Text(
            context.locale.languageCode == 'ar'
                ? 'القبول بالشروط: باستخدامك للتطبيق فإنك توافق على الشروط.\n\n'
                      'الأهلية: يجب ألا يقل عمرك عن 18 عامًا.\n\n'
                      'سلوك المستخدم: يمنع نشر المحتوى المسيء.\n\n'
                      'إنهاء الاستخدام: نحتفظ بالحق في إنهاء حسابك.'
                : 'Acceptance: By using the app you agree to the terms.\n\n'
                      'Eligibility: You must be at least 18 years old.\n\n'
                      'User Conduct: Offensive content is prohibited.\n\n'
                      'Termination: We reserve the right to terminate your account.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('about'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car,
              size: 60,
              color: Color(0xFF0A2E5C),
            ),
            const SizedBox(height: 16),
            const Text(
              'CarSocial',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('الإصدار 1.0.0 / Version 1.0.0'),
            const SizedBox(height: 16),
            Text(
              context.locale.languageCode == 'ar'
                  ? 'كل ما يخص السيارات في مكان واحد\nبيع وشراء وخدمات السيارات في مصر'
                  : 'Everything about cars in one place\nBuy, sell, and car services in Egypt',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 CarSocial\n${context.locale.languageCode == 'ar' ? 'جميع الحقوق محفوظة' : 'All rights reserved'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_account'.tr()),
        content: Text('delete_account_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordDialog();
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('enter_password'.tr()),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'password'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(passwordController.text);
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String password) async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (var post in posts.docs) {
        await post.reference.delete();
      }

      await user.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('account_deleted'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'delete_failed'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text(
          context.locale.languageCode == 'ar'
              ? 'هل أنت متأكد من تسجيل الخروج؟'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr()), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Dark Mode Switch
          SwitchListTile(
            title: Text('dark_mode'.tr()),
            subtitle: Text('dark_mode_sub'.tr()),
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: _isDarkMode ? Colors.amber : const Color(0xFFFF6B00),
            ),
            value: _isDarkMode,
            onChanged: _toggleTheme,
          ),
          const Divider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF0066CC)),
            title: Text('language'.tr()),
            subtitle: Text(_currentLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageDialog,
          ),
          const Divider(),

          // Biometric
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) return const SizedBox();

              return FutureBuilder<bool>(
                future: BiometricService.canCheckBiometrics(),
                builder: (context, canCheckSnapshot) {
                  if (!canCheckSnapshot.hasData || !canCheckSnapshot.data!) {
                    return const SizedBox();
                  }

                  return FutureBuilder<bool>(
                    future: BiometricService.isBiometricEnabled(user.uid),
                    builder: (context, enabledSnapshot) {
                      final isEnabled = enabledSnapshot.data ?? false;

                      return Column(
                        children: [
                          SwitchListTile(
                            title: Text('biometric_login'.tr()),
                            subtitle: Text('biometric_sub'.tr()),
                            secondary: const Icon(
                              Icons.fingerprint,
                              color: Color(0xFF0066CC),
                            ),
                            value: isEnabled,
                            onChanged: (value) async {
                              if (value) {
                                final authenticated =
                                    await BiometricService.authenticate(
                                      reason: 'enable_biometric'.tr(),
                                    );
                                if (authenticated && mounted) {
                                  await BiometricService.setBiometricEnabled(
                                    user.uid,
                                    true,
                                  );
                                  if (mounted) setState(() {});
                                }
                              } else {
                                await BiometricService.setBiometricEnabled(
                                  user.uid,
                                  false,
                                );
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF0066CC)),
            title: Text('privacy_policy'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          const Divider(),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF0066CC)),
            title: Text('terms_of_service'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTermsOfService,
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF0066CC)),
            title: Text('about'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAboutDialog,
          ),
          const Divider(),

          // Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'delete_account'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: _deleteAccount,
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
