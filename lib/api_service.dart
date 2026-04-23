import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // 📌 เพิ่ม import นี้เพื่อรองรับการส่งไฟล์รูปภาพแบบ Bytes

class ApiService {
  static const String baseUrl = "https://thaimusic-admin.com/ThaiMusic_Admin";

  // 1. ฟังก์ชันดึงข้อมูล About และ Contact
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final url = Uri.parse("$baseUrl/app_get_settings.php");
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

  // 2. ฟังก์ชันเพิ่มข้อมูลผู้ใช้
  static Future<void> insertUser({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/app_register.php");

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
      final url = Uri.parse("$baseUrl/app_login.php");
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

  // 4. ฟังก์ชันดึงข้อมูลโปรไฟล์ 
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/app_get_profile.php?user_id=$userId");
      final response = await http.get(url);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"status": "error", "message": "Server Error"};
    } catch (e) {
      return {"status": "error", "message": "Connection Failed"};
    }
  }

  // 5. ฟังก์ชันอัปเดตข้อมูลโปรไฟล์ (📌 แก้ไขให้ส่งรูปภาพและอีเมลได้)
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fname,
    required String lname,
    required String email,    // 📌 เพิ่มรับค่า email
    required String password,
    Uint8List? imageBytes,    // 📌 เพิ่มรับค่าไฟล์รูปภาพ
    String? imageName,        // 📌 เพิ่มรับค่าชื่อไฟล์รูปภาพ
  }) async {
    try {
      final url = Uri.parse("$baseUrl/app_update_profile.php");
      
      // 📌 เปลี่ยนจาก http.post ธรรมดา เป็น MultipartRequest เพื่อให้ส่งไฟล์ได้
      var request = http.MultipartRequest('POST', url);

      // แนบข้อมูลตัวอักษร
      request.fields['user_id'] = userId;
      request.fields['fname'] = fname;
      request.fields['lname'] = lname;
      request.fields['email'] = email;
      request.fields['password'] = password;

      // แนบไฟล์รูปลงไปด้วยถ้ามีการอัปโหลดรูปใหม่
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'img', 
            imageBytes, 
            filename: imageName ?? 'profile_pic.jpg'
          ),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(respStr);
      }
      return {"status": "error", "message": "Server Error"};
    } catch (e) {
      return {"status": "error", "message": "Connection Failed"};
    }
  }

  // 6. ฟังก์ชันดึงรายชื่อวงดนตรี
  static Future<Map<String, dynamic>> getEnsembles() async {
    try {
      final url = Uri.parse("$baseUrl/app_get_ensembles.php");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Failed: $e'};
    }
  }

  // 7. ฟังก์ชันดึงรายชื่อเพลงตามไอดีวงดนตรี
  static Future<Map<String, dynamic>> getSongs(String ensembleId) async {
    try {
      final url = Uri.parse("$baseUrl/app_get_songs.php?ensemble_id=$ensembleId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Failed: $e'};
    }
  }

  // 8. ฟังก์ชันดึงรายการแทร็กเครื่องดนตรี (📌 เพิ่มใหม่สำหรับหน้า Play Music)
  static Future<Map<String, dynamic>> getTracks(String songId) async {
    try {
      final url = Uri.parse("$baseUrl/app_get_tracks.php?song_id=$songId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Failed: $e'};
    }
  }
}