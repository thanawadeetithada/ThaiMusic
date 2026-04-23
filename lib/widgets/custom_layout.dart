import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

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
class FullScreenMenu extends StatefulWidget {
  const FullScreenMenu({super.key});

  @override
  State<FullScreenMenu> createState() => _FullScreenMenuState();
}

class _FullScreenMenuState extends State<FullScreenMenu> {
  bool _isLoggedIn = false;
  String _firstName = "กำลังโหลด...";
  String? _profileImageUrl; // 📌 ตัวแปรเก็บ URL รูปภาพ
  bool _isLoading = true;

  final String baseUrl = "https://thaimusic-admin.com/";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📌 ฟังก์ชันตรวจสอบ Session และดึงข้อมูลจาก Database
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? userId = prefs.getString('user_id');

    if (loggedIn && userId != null) {
      // ดึงข้อมูลโปรไฟล์จากฐานข้อมูล
      var result = await ApiService.getProfile(userId);
      if (result['status'] == 'success') {
        setState(() {
          _isLoggedIn = true;
          _firstName = result['data']['first_name'] ?? "ผู้ใช้งาน";
          _profileImageUrl = result['data']['profile_image']; // 📌 เก็บ URL รูป
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoggedIn = true;
          _firstName = "ผู้ใช้งาน";
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  // 📌 ฟังก์ชันออกจากระบบ
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

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
            
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_isLoggedIn)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 📌 เช็คการแสดงรูปโปรไฟล์
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty && _profileImageUrl != "default.png")
                            ? NetworkImage(baseUrl + _profileImageUrl!)
                            : null,
                        child: (_profileImageUrl == null || _profileImageUrl!.isEmpty || _profileImageUrl == "default.png")
                            ? const Icon(Icons.person, color: Colors.black, size: 30) // แสดง Icon ถ้าไม่มีรูป
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _firstName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  // ปุ่มออกจากระบบ
                  TextButton(
                    onPressed: _logout,
                    child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  )
                ],
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
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
                    Text(
                      "เข้าสู่ระบบ", 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            
            // รายการเมนู
            _buildMenuItem("หน้าหลัก", () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/main');
            }),
            _buildMenuItem("ข้อมูลส่วนตัว", () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/profile'); 
            }),
            _buildMenuItem("เกี่ยวกับ", () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/about'); 
            }),
            _buildMenuItem("ติดต่อเรา", () {
              Navigator.pop(context);
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