import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/theme_provider.dart';
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
import 'screens/onboarding_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CarSocial',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
              '/services': (context) => const ServicesScreen(),
              '/wanted': (context) => const WantedScreen(),
              '/search': (context) => const SearchScreen(),
              '/stories': (context) => const StoriesScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/chat': (context) => const ChatScreen(
                  chatId: '', otherUserId: '', otherUserName: ''),
              '/edit_profile': (context) => const EditProfileScreen(),
              '/other_profile': (context) => const OtherProfileScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              '/car_report': (context) => const CarReportScreen(),
              '/community': (context) => const CommunityScreen(),
              '/leaderboard': (context) => const LeaderboardScreen(),
              '/feed': (context) => const FeedScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
            },
          );
        },
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
