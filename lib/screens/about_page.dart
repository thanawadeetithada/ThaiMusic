import 'package:flutter/material.dart';
import '../widgets/custom_layout.dart';
import '../api_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "เกี่ยวกับ",
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getAppSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data?['status'] == 'error') {
            return const Center(child: Text("ไม่สามารถโหลดข้อมูลได้", style: TextStyle(fontSize: 18)));
          }

          final data = snapshot.data?['data'];

          // เปลี่ยนเป็น SingleChildScrollView เพื่อป้องกันเนื้อหาล้นจอ (Responsive)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0), // ลด Padding ลงเล็กน้อยเพื่อให้ดูดีบนจอเล็ก
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // บังคับให้ลูกขยายเต็มความกว้าง
                children: [
                  // ส่วนหัวสีขาว
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: Text(
                      data?['about_title'] ?? "แอพฝึกซ้อมดนตรีไทย",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // เส้นคั่นบางๆ เพื่อความสวยงาม
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  
                  // ส่วนเนื้อหา
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                    ),
                    child: Text(
                      data?['about_content'] ?? "ไม่มีข้อมูลเนื้อหา",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.6), // เพิ่ม height เพื่อให้อ่านง่ายขึ้น
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}