import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; // สำคัญ: ต้องใช้เพื่อดึงแผนที่จริง
import '../widgets/custom_layout.dart';
import '../api_service.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // ฟังก์ชันสำหรับเปิด Google Maps แบบเอาพิกัดไปด้วย (อัปเดต URL ให้แม่นยำขึ้น)
  Future<void> _openGoogleMaps(String lat, String lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri mapUri = Uri.parse(googleMapsUrl);
    
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("ไม่สามารถเปิดแผนที่ได้: $googleMapsUrl");
    }
  }

  // ฟังก์ชันสำหรับกดโทรออก
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri.parse('tel:$cleanPhone');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint("ไม่สามารถโทรออกได้: $phoneNumber");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "ติดต่อเรา",
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
          
          // ดึงพิกัดจาก DB และแปลงเป็น double เพื่อใช้กับ GoogleMap
          final double lat = double.tryParse(data?['map_latitude']?.toString() ?? "") ?? 13.7944;
          final double lng = double.tryParse(data?['map_longitude']?.toString() ?? "") ?? 100.3206;
          final LatLng mapPosition = LatLng(lat, lng); // สร้างจุดพิกัด

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ข้อมูลการติดต่อ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                _buildContactRow(Icons.location_on_outlined, data?['contact_address'] ?? "-"),
                
                // ข้อมูลเบอร์โทร: ส่ง onTap ไปให้กดได้ และสีจะเป็นสีดำปกติ
                _buildContactRow(
                  Icons.phone_outlined, 
                  data?['contact_phone'] ?? "-",
                  onTap: () => _makePhoneCall(data?['contact_phone'] ?? ""),
                ),
                
                _buildContactRow(Icons.email_outlined, data?['contact_email'] ?? "-"),
                _buildContactRow(Icons.access_time, data?['contact_hours']?.replaceAll('\\n', '\n') ?? "-"),

                const SizedBox(height: 30),
                const Text("แผนที่", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // 📍 กรอบแสดงแผนที่ Google Maps ของจริง (เลื่อนได้ ซูมได้)
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: mapPosition,
                        zoom: 15.0, // ระดับการซูมเริ่มต้น
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('contact_marker'),
                          position: mapPosition,
                          infoWindow: const InfoWindow(title: 'สถานที่ติดต่อ'),
                        ),
                      },
                      zoomGesturesEnabled: true, // อนุญาตให้ซูม
                      scrollGesturesEnabled: true, // อนุญาตให้เลื่อน
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ปุ่มกดเด้งไป Google Maps ของจริง
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openGoogleMaps(lat.toString(), lng.toString()),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("เปิดพิกัดใน Google Maps", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123E6C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ปรับปรุงส่วนแสดงผลให้เป็นสีดำล้วน ไม่มีขีดล่าง แต่ยังรับค่าการกด (onTap) ได้
  Widget _buildContactRow(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell( 
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: Colors.black87), 
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16, 
                    height: 1.4,
                    color: Colors.black87, 
                    decoration: TextDecoration.none, 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}