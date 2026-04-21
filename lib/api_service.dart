import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://localhost/ThaiMusic_Admin";

  // 1. ฟังก์ชันดึงข้อมูล About และ Contact (ที่ระบบฟ้องว่าหาไม่เจอ)
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final url = Uri.parse("$baseUrl/get_settings.php");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"status": "error", "message": "Server Error"};
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Failed: $e"};
    }
  }

  // 2. ฟังก์ชันเพิ่มข้อมูลผู้ใช้ (ที่คุณสร้างไว้ตอนแรก)
  static Future<void> insertUser({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register.php");

    final response = await http.post(url, body: {
      "fname": fname,
      "lname": lname,
      "email": email,
      "password": password,
    });

    final data = json.decode(response.body);
    if (data["status"] == "success") {
      print("✅ บันทึกข้อมูลสำเร็จ");
    } else {
      print("❌ เกิดข้อผิดพลาด: ${data["message"]}");
    }
  }

  // 3. ฟังก์ชันเข้าสู่ระบบ
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/login.php");
      final response = await http.post(url, body: {
        "email": email,
        "password": password,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"status": "error", "message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Connection failed: $e"};
    }
  }
}