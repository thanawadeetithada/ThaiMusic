import 'package:flutter/material.dart';
import '../widgets/custom_layout.dart';
import '../api_service.dart';
import 'play_music.dart'; // 📌 1. ต้อง import ไฟล์หน้าเล่นเพลงเข้ามาที่นี่ด้วย

class SongsPage extends StatefulWidget {
  final String ensembleId;
  final String ensembleName;

  const SongsPage({super.key, required this.ensembleId, required this.ensembleName});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  bool isLoading = true;
  List<dynamic> songs = [];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    var result = await ApiService.getSongs(widget.ensembleId);
    if (result['status'] == 'success') {
      setState(() {
        songs = result['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "เพลงใน${widget.ensembleName}",
      body: Column(
        children: [
          // ปุ่มย้อนกลับ
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 10.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF123E6C)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // 📌 2. เพิ่มระยะห่างเพื่อให้ Card เพลงเลื่อนลงมา ไม่ชิดปุ่มกลับ
          const SizedBox(height: 20), 

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : songs.isEmpty
                    ? const Center(child: Text("ยังไม่มีเพลงในวงนี้", style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          var song = songs[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 15), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              
                              // 📌 3. เพิ่มระยะห่างระหว่างวงกลมสีเหลืองกับชื่อเพลง
                              horizontalTitleGap: 30, 
                              
                              leading: const CircleAvatar(
                                radius: 25, 
                                backgroundColor: Color(0xFFd4af37), // สีทอง
                                child: Icon(Icons.music_note, color: Colors.white, size: 28),
                              ),
                              title: Text(
                                song['title'], 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              // 📌 ลบ subtitle แสดง BPM ออกไปแล้ว
                              trailing: const Icon(Icons.play_circle_fill, color: Color(0xFF123E6C), size: 38),
                              onTap: () {
                                // 📌 4. แก้ไขการ Navigation: ใช้ push แทน pushNamed เพื่อให้ทำงานได้ทันที
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlayMusicPage(),
                                    // ส่งค่าผ่าน settings เพื่อให้หน้า PlayMusicPage รับค่าผ่าน ModalRoute ได้เหมือนเดิม
                                    settings: RouteSettings(
                                      arguments: {
                                        'song_id': song['song_id'].toString(), 
                                        'song_title': song['title']
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}