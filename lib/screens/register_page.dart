import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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

  File? _selectedImage;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> registerUser() async {
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    final trimmedEmail = email.text.trim();
    if (!isValidEmail(trimmedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')),
      );
      return;
    }

    final url = Uri.parse('http://localhost/phpAPI/register.php');
    var request = http.MultipartRequest('POST', url);

    request.fields['fname'] = fname.text.trim();
    request.fields['lname'] = lname.text.trim();
    request.fields['email'] = email.text.trim();
    request.fields['password'] = password.text.trim();

    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('img', _selectedImage!.path),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (respStr.contains('success')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
          );
          Navigator.pop(context);
        } else if (respStr.contains('อีเมลนี้มีผู้ใช้แล้ว')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อีเมลนี้มีผู้ใช้แล้ว')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ผิดพลาด: $respStr')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 171, 212, 241),
              Color.fromARGB(255, 253, 253, 253)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : null,
                        child: _selectedImage == null
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
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
                        controller: email, hintExample: 'example@gmail.com'),
                    const SizedBox(height: 15),
                    _buildTextField('รหัสผ่าน',
                        controller: password, obscure: true),
                    const SizedBox(height: 15),
                    _buildTextField('ยืนยันรหัสผ่าน',
                        controller: confirmPassword, obscure: true),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: 150,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('สมัครสมาชิก',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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
      ),
    );
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Widget _buildTextField(String hint,
      {bool obscure = false,
      String? hintExample,
      TextEditingController? controller}) {
    final isPasswordField = hint == 'รหัสผ่าน';
    final isConfirmPasswordField = hint == 'ยืนยันรหัสผ่าน';

    return Material(
      elevation: 3,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(25),
      child: TextField(
        controller: controller,
        obscureText: obscure
            ? (isPasswordField ? _obscurePassword : _obscureConfirmPassword)
            : false,
        decoration: InputDecoration(
          hintText: hintExample ?? hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          suffixIcon: obscure
              ? Padding(
                  padding:
                      const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      (isPasswordField && _obscurePassword) ||
                              (isConfirmPasswordField &&
                                  _obscureConfirmPassword)
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