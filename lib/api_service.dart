import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://localhost/phpAPI";

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
}
