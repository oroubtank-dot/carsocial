import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currentLanguage;
  String _selectedLanguage = 'ar';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage = context.locale.languageCode;
    _currentLanguage =
        context.locale.languageCode == 'ar' ? 'العربية' : 'English';
  }

  void _changeLanguage(String language) {
    final langCode = language == 'العربية' ? 'ar' : 'en';
    context.setLocale(Locale(langCode));
    setState(() {
      _currentLanguage = language;
      _selectedLanguage = langCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('language_changed'.tr()),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLanguageDialog() {
    final isArabic = _selectedLanguage == 'ar';
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
            'نحن في CarSocial نلتزم بحماية خصوصيتك...\n\n'
            'سياسة الخصوصية الخاصة بنا توضح كيفية جمع واستخدام بياناتك.',
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
            'باستخدامك للتطبيق فإنك توافق على الشروط التالية...\n\n'
            'يمنع نشر محتوى مسيء أو مخالف للقوانين.',
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('about'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car,
                size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('CarSocial',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('الإصدار 1.0.0'),
            const SizedBox(height: 16),
            Text(
              'كل ما يخص السيارات في مكان واحد\nبيع وشراء وخدمات السيارات في مصر',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('© 2026 CarSocial',
                style: TextStyle(color: Colors.grey.shade600)),
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('dark_mode'.tr()),
            subtitle: Text('dark_mode_sub'.tr()),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.amber : AppColors.secondary,
            ),
            value: isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: Text('language'.tr()),
            subtitle: Text(_currentLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
            title: Text('privacy_policy'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: Text('terms_of_service'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTermsOfService,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.primary),
            title: Text('about'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAbout,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
