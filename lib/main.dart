import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/music_page.dart';
import 'screens/splash_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
import 'screens/about_page.dart';
import 'screens/contact_page.dart';

void main() {
  runApp(const MyApp());
}

bool isUserLoggedIn = false; 

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    final initialUri = await _appLinks!.getInitialAppLink();
    _handleLink(initialUri?.toString());

    _appLinks!.uriLinkStream.listen((uri) {
      _handleLink(uri.toString());
    });
  }

  void _handleLink(String? link) {
    if (link == null) return;
    print("🔥 Deep Link: $link");
    if (link.startsWith("appreset://success")) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thai Music App',
      theme: ThemeData(
        fontFamily: 'Kanit',
        primaryColor: const Color(0xFF123E6C),
      ),
      initialRoute: "/splash", 
      routes: {
        '/splash': (context) => const SplashPage(),
        '/main': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/about': (context) => const AboutPage(),
        '/contact': (context) => const ContactPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/reset': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResetPasswordPage(email: args['email']);
        },
        '/thaimusic': (context) => const MusicPage(),
      },
    );
  }
}