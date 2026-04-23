import 'package:flutter/material.dart';
import '../widgets/custom_layout.dart';
import '../api_service.dart';
import 'songs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  List<dynamic> ensembles = [];

  @override
  void initState() {
    super.initState();
    _fetchEnsembles();
  }

  Future<void> _fetchEnsembles() async {
    var result = await ApiService.getEnsembles();
    if (result['status'] == 'success') {
      setState(() {
        ensembles = result['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "วงดนตรี",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ensembles.isEmpty
              ? const Center(child: Text("ไม่มีข้อมูลวงดนตรี", style: TextStyle(fontSize: 18)))
              : Center( // 📌 จัดให้อยู่กึ่งกลางแนวตั้งของหน้าจอ
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      // 📌 เปลี่ยนจาก GridView มาใช้ Wrap เพื่อให้ของชิ้นเดียวอยู่ตรงกลางแนวนอนได้
                      child: Wrap(
                        alignment: WrapAlignment.center, // 📌 จัดให้อยู่กึ่งกลางแนวนอน
                        spacing: 20, // ระยะห่างแนวนอนระหว่างปุ่ม
                        runSpacing: 20, // ระยะห่างแนวตั้งระหว่างปุ่ม
                        children: ensembles.map<Widget>((ensemble) {
                          return SizedBox(
                            width: 250, // 📌 ขนาดความกว้างของปุ่ม (ปรับลดเพิ่มได้ที่นี่)
                            height: 60, // 📌 ขนาดความสูงของปุ่ม (ปรับลดเพิ่มได้ที่นี่)
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF123E6C), // สีกรมท่า
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15), // ขอบมน
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SongsPage(
                                      ensembleId: ensemble['ensemble_id'].toString(),
                                      ensembleName: ensemble['name'],
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                ensemble['name'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }
}