import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; 
import '../widgets/custom_layout.dart';
import '../api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  String currentUserId = "";

  TextEditingController fnameCtrl = TextEditingController();
  TextEditingController lnameCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController(); 
  TextEditingController passCtrl = TextEditingController();
  TextEditingController confirmPassCtrl = TextEditingController();

  // ตัวแปรสำหรับรูปภาพ
  String? currentImageUrl; // URL รูปเดิมจาก DB
  Uint8List? _imageBytes; // ไฟล์รูปใหม่ที่เพิ่งเลือก
  String? _imageName;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoadData();
  }

  Future<void> _checkSessionAndLoadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? userId = prefs.getString('user_id');

    if (!loggedIn || userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    currentUserId = userId;
    
    var result = await ApiService.getProfile(currentUserId);
    if (result['status'] == 'success') {
      var data = result['data'];
      setState(() {
        fnameCtrl.text = data['first_name'] ?? "";
        lnameCtrl.text = data['last_name'] ?? "";
        emailCtrl.text = data['email'] ?? "";
        currentImageUrl = data['profile_image']; // เก็บ Path รูปจาก DB
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  // 📌 ฟังก์ชันเลือกรูป
  Future<void> _pickImage() async {
    if (!isEditing) return; // ให้เลือกรูปได้เฉพาะตอนกด 'แก้ไข'

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

  Future<void> _saveProfile() async {
    if (passCtrl.text.isNotEmpty && passCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")));
      return;
    }

    setState(() => isLoading = true);

    var result = await ApiService.updateProfile(
      userId: currentUserId,
      fname: fnameCtrl.text,
      lname: lnameCtrl.text,
      email: emailCtrl.text, // ส่ง email ไปอัปเดตด้วย
      password: passCtrl.text,
      imageBytes: _imageBytes, // ส่งรูปใหม่ไปอัปเดต
      imageName: _imageName,
    );

    if (result['status'] == 'success') {
      setState(() {
        isEditing = false;
        passCtrl.clear();
        confirmPassCtrl.clear();
        _imageBytes = null; // ล้างคิวอัปโหลดเมื่อสำเร็จ
      });
      _checkSessionAndLoadData(); // โหลดรูปและข้อมูลใหม่มาแสดง
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อย"), backgroundColor: Colors.green)
        );
      }
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  // ตัวดึงรูปมาแสดงผล
  ImageProvider<Object>? _getProfileImage() {
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!); // รูปใหม่ที่เพิ่งเลือก
    } else if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      return NetworkImage('https://thaimusic-admin.com/$currentImageUrl'); // รูปเดิมจากฐานข้อมูล
    }
    return null; // ไม่มีรูปเลย (ให้แสดง Icon)
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "ข้อมูลส่วนตัว",
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 📌 ส่วนแสดงรูปโปรไฟล์
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null 
                      ? const Icon(Icons.person_outline, size: 80, color: Colors.black54)
                      : null,
                  ),
                  if (isEditing) // โชว์ไอคอนกล้องเฉพาะตอนกดแก้ไข
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    )
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildTextField("ชื่อ", fnameCtrl),
            _buildTextField("นามสกุล", lnameCtrl),
            _buildTextField("อีเมล", emailCtrl), // ตอนนี้เปิดให้แก้ไขได้แล้วตามโหมด isEditing
            
            if (isEditing) ...[
              _buildTextField("รหัสผ่านใหม่ (เว้นว่างได้ถ้าไม่เปลี่ยน)", passCtrl, isPassword: true),
              _buildTextField("ยืนยันรหัสผ่าน", confirmPassCtrl, isConfirmPassword: true),
            ],

            const SizedBox(height: 30),

            if (!isEditing)
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3AD46),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () => setState(() => isEditing = true),
                  child: const Text("แก้ไข", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _saveProfile,
                      child: const Text("ตกลง", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          passCtrl.clear();
                          confirmPassCtrl.clear();
                          _imageBytes = null; // คืนค่าเดิมถ้ายกเลิก
                          isLoading = true; 
                        });
                        _checkSessionAndLoadData(); // โหลดข้อมูลเก่ามาใหม่ถ้ายกเลิก
                      },
                      child: const Text("ยกเลิก", style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 📌 อัปเดตช่องกรอกข้อความให้มีรูปตาปิด/เปิด
  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, bool isConfirmPassword = false}) {
    bool isObscureField = isPassword || isConfirmPassword;
    bool currentObscureState = isPassword ? _obscurePassword : _obscureConfirmPassword;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: !isEditing ? Colors.grey[200] : Colors.white, // เป็นสีเทาถ้าไม่ได้กดแก้ไข
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: controller,
              enabled: isEditing, // แก้อีเมล ชื่อ นามสกุลได้แล้วถ้า isEditing เป็น true
              obscureText: isObscureField ? currentObscureState : false,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                suffixIcon: isObscureField && isEditing
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Icon(
                            currentObscureState ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isPassword) _obscurePassword = !_obscurePassword;
                              if (isConfirmPassword) _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}