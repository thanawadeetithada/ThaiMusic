import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data'; 
import '../widgets/custom_layout.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fname = TextEditingController();
  final TextEditingController lname = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<void> registerUser() async {
    if (fname.text.trim().isEmpty ||
        lname.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        confirmPassword.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    if (!isValidEmail(email.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')),
      );
      return;
    }

    final url = Uri.parse('https://thaimusic-admin.com/ThaiMusic_Admin/app_register.php');
    var request = http.MultipartRequest('POST', url);

    request.fields['fname'] = fname.text.trim();
    request.fields['lname'] = lname.text.trim();
    request.fields['email'] = email.text.trim();
    request.fields['password'] = password.text.trim();

    if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'img', 
          _imageBytes!,
          filename: _imageName ?? 'profile_pic.jpg',
        ),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = json.decode(respStr);
        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('สมัครสมาชิกสำเร็จ!'), 
                backgroundColor: Colors.green,
              ),
            );
            // 📌 บังคับเปลี่ยน URL กลับไปหน้า Login
            Navigator.pushReplacementNamed(context, '/login'); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'เกิดข้อผิดพลาด')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งข้อมูล: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "สมัครสมาชิก",
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                      child: _imageBytes == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'เพิ่มรูปภาพ',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField('ชื่อ', controller: fname),
                  const SizedBox(height: 15),
                  _buildTextField('นามสกุล', controller: lname),
                  const SizedBox(height: 15),
                  _buildTextField('อีเมล',
                      controller: email,
                      hintExample: 'example@gmail.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField('รหัสผ่าน',
                      controller: password,
                      obscure: true,
                      keyboardType: TextInputType.visiblePassword),
                  const SizedBox(height: 15),
                  _buildTextField('ยืนยันรหัสผ่าน',
                      controller: confirmPassword,
                      obscure: true,
                      keyboardType: TextInputType.visiblePassword),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('สมัครสมาชิก',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      // 📌 บังคับให้เปลี่ยน URL กลับหน้า Login เมื่อกดยกเลิก
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Widget _buildTextField(String hint,
      {bool obscure = false,
      String? hintExample,
      TextEditingController? controller,
      TextInputType keyboardType = TextInputType.text}) {
    final isPasswordField = hint == 'รหัสผ่าน';
    final isConfirmPasswordField = hint == 'ยืนยันรหัสผ่าน';

    return Material(
      elevation: 3,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(25),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure
            ? (isPasswordField ? _obscurePassword : _obscureConfirmPassword)
            : false,
        decoration: InputDecoration(
          hintText: hintExample ?? hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          suffixIcon: obscure
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      (isPasswordField && _obscurePassword) ||
                              (isConfirmPasswordField && _obscureConfirmPassword)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPasswordField) {
                          _obscurePassword = !_obscurePassword;
                        } else if (isConfirmPasswordField) {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }
                      });
                    },
                  ),
                )
              : null,
        ),
      ),
    );
  }
}