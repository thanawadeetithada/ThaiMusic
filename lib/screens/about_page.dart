import 'package:flutter/material.dart';
import '../widgets/custom_layout.dart';
import '../api_service.dart'; // อย่าลืม import ไฟล์ API

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "เกี่ยวกับ",
      body: FutureBuilder<Map<String, dynamic>>(
        // เรียกฟังก์ชันดึงข้อมูลจากฐานข้อมูล
        future: ApiService.getAppSettings(),
        builder: (context, snapshot) {
          // ระหว่างรอโหลดข้อมูล ให้แสดงวงกลมหมุนๆ
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ถ้าโหลดข้อมูลไม่สำเร็จ หรือมี Error
          if (snapshot.hasError || snapshot.data?['status'] == 'error') {
            return const Center(child: Text("ไม่สามารถโหลดข้อมูลได้", style: TextStyle(fontSize: 18)));
          }

          // ถ้าโหลดสำเร็จ ดึงข้อมูลมาใช้งาน
          final data = snapshot.data?['data'];

          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      // ส่วนหัวสีขาว
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                      // ส่วนเนื้อหา (กรอบเทาอ่อนด้านในตามรูป)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                        ),
                        child: Text(
                          data?['about_content'] ?? "ไม่มีข้อมูลเนื้อหา",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}