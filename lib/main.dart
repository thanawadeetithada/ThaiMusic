import 'package:flutter/material.dart';
import 'screens/loging_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/music_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ThaiMusic',
      theme: ThemeData(
        fontFamily: 'Prompt',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/reset': (context) => const ResetPasswordPage(),
        '/thaimusic': (context) => const MusicPage(),
      },
    );
  }
}
