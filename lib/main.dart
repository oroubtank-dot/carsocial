import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/services_screen.dart';
import 'screens/wanted_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/search_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/other_profile_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/car_report_screen.dart';
import 'screens/community_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDpD9Du-Lmc40uJaY-uywZ22azKa6X-iA0',
      authDomain: 'corsocial-6b3ef.firebaseapp.com',
      projectId: 'corsocial-6b3ef',
      storageBucket: 'corsocial-6b3ef.firebasestorage.app',
      messagingSenderId: '1084647387259',
      appId: '1:1084647387259:web:c300b037e1f7613d9132de',
    ),
  );

  await CacheService.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'CarSocial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/subscription': (context) => const SubscriptionScreen(),
          '/services': (context) => const ServicesScreen(),
          '/wanted': (context) => const WantedScreen(),
          '/search': (context) => const SearchScreen(),
          '/stories': (context) => const StoriesScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/chat': (context) =>
              const ChatScreen(chatId: '', otherUserId: '', otherUserName: ''),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/other_profile': (context) => const OtherProfileScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/car_report': (context) => const CarReportScreen(),
          '/community': (context) => const CommunityScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/feed': (context) => const FeedScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

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
    _selectedLanguage = context.locale.languageCode;
    _currentLanguage =
        context.locale.languageCode == 'ar' ? 'العربية' : 'English';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLanguage =
        context.locale.languageCode == 'ar' ? 'العربية' : 'English';
    _selectedLanguage = context.locale.languageCode;
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
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF0066CC)),
            title: Text('language'.tr()),
            subtitle: Text(_currentLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF0066CC)),
            title: Text('privacy_policy'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF0066CC)),
            title: Text('terms_of_service'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF0066CC)),
            title: Text('about'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
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

// LoginScreen placeholder
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen')),
    );
  }
}
