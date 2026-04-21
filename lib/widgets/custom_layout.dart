import 'package:flutter/material.dart';
import '../../main.dart'; // ตรวจสอบให้แน่ใจว่า import ไฟล์ main.dart เพื่อดึงตัวแปร isUserLoggedIn มาใช้

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const CustomScaffold({super.key, required this.title, required this.body});

  void _showFullScreenMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const FullScreenMenu();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF123E6C),
        elevation: 0,
        centerTitle: false,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 30),
            onPressed: () => _showFullScreenMenu(context),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD6E8F6), // ฟ้าอ่อน
              Color(0xFFE9EAF1), // เทาอมชมพูอ่อน
            ],
          ),
        ),
        child: body,
      ),
    );
  }
}

// --------- เมนูแบบเต็มหน้าจอ (Full Screen Menu) ---------
class FullScreenMenu extends StatelessWidget {
  const FullScreenMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),
            
            // ส่วนแสดงโปรไฟล์ หรือ ปุ่มเข้าสู่ระบบ
            if (isUserLoggedIn)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.black, size: 30),
                  ),
                  SizedBox(width: 15),
                  Text("Thanawadee", 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // ปิดเมนูก่อน
                  Navigator.pushNamed(context, '/login'); // เปิดหน้า Login
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.black, size: 30),
                    ),
                    SizedBox(width: 15),
                    Text("เข้าสู่ระบบ", 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            
            const SizedBox(height: 50),
            
            // รายการเมนู
            _buildMenuItem("หน้าหลัก", () {
              Navigator.pop(context); // ปิดเมนู
              Navigator.pushReplacementNamed(context, '/main'); // สลับไปหน้าหลัก
            }),
            _buildMenuItem("ข้อมูลส่วนตัว", () {
              Navigator.pop(context);
              // เปลี่ยนจาก pushNamed เป็น pushReplacementNamed
              Navigator.pushReplacementNamed(context, '/profile'); 
            }),
            _buildMenuItem("เกี่ยวกับ", () {
              Navigator.pop(context);
              // เปลี่ยนจาก pushNamed เป็น pushReplacementNamed
              Navigator.pushReplacementNamed(context, '/about'); 
            }),
            _buildMenuItem("ติดต่อเรา", () {
              Navigator.pop(context);
              // เปลี่ยนจาก pushNamed เป็น pushReplacementNamed
              Navigator.pushReplacementNamed(context, '/contact'); 
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}