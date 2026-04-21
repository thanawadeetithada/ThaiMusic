import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลา 2 วินาทีแล้วไปหน้า Main
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF123E6C)), // สีพื้นหลังโลโก้
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ใส่รูปโลโก้ของคุณตรงนี้
            Icon(Icons.music_note, color: Colors.white, size: 100),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}