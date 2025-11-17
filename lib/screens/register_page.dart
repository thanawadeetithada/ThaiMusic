import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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

  http.Client createInsecureHttpClient() {
    if (kDebugMode && Platform.isAndroid) {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      return IOClient(httpClient);
    }
    return http.Client();
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

    final trimmedEmail = email.text.trim();
    if (!isValidEmail(trimmedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')),
      );
      return;
    }

    final client = createInsecureHttpClient();
    const String apiUrl = 'https://bermine-thailand.com/register.php';
    final url = Uri.parse(apiUrl);

    var request = http.MultipartRequest('POST', url);

    request.fields['fname'] = fname.text.trim();
    request.fields['lname'] = lname.text.trim();
    request.fields['email'] = email.text.trim();
    request.fields['password'] = password.text.trim();

    if (_selectedImage != null) {
      try {
        request.files.add(
          await http.MultipartFile.fromPath('img', _selectedImage!.path),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถเพิ่มไฟล์รูปภาพ: $e')),
          );
        }
        client.close();
        return;
      }
    }

    try {
      final response = await client.send(request);
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (respStr.contains('success')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
            );
            Navigator.pop(context);
          }
        } else if (respStr.contains('อีเมลนี้มีผู้ใช้แล้ว')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('อีเมลนี้มีผู้ใช้แล้ว')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ผิดพลาด: $respStr')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (${response.statusCode})'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        backgroundColor: const Color.fromARGB(255, 171, 212, 241),
        elevation: 0,
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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

                    // ปุ่มสมัครสมาชิก
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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