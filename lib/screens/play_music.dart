import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class PlayMusicPage extends StatefulWidget {
  const PlayMusicPage({super.key});

  @override
  State<PlayMusicPage> createState() => _PlayMusicPageState();
}

class TrackItem {
  final String id;
  final String name;
  final String iconUrl;
  final String audioUrl;
  final Color color;
  bool isMuted;
  final AudioPlayer player;
  bool isLoaded; // Track if the source loaded successfully

  TrackItem({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.audioUrl,
    required this.color,
    this.isMuted = false,
    required this.player,
    this.isLoaded = false,
  });
}

class _PlayMusicPageState extends State<PlayMusicPage> {
  bool isLoading = true;
  String songTitle = "";
  String songId = "";
  
  List<TrackItem> tracks = [];
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  // URL อาจจะต้องเปลี่ยนตามการใช้งาน (10.0.2.2 หรือ localhost หรือ IP จริง)
  final String baseImageUrl = "https://thaimusic-admin.com/ThaiMusic_Admin/uploads/images/";
  final String baseAudioUrl = "https://thaimusic-admin.com/ThaiMusic_Admin/uploads/audio/";

  @override
  void initState() {
    super.initState();
    // 1. บังคับหน้าจอเป็นแนวนอน
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (songId.isEmpty) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      songId = args['song_id'];
      songTitle = args['song_title'];
      _initData();
    }
  }

  Future<void> _initData() async {
    try {
      var result = await ApiService.getTracks(songId);
      if (result['status'] == 'success') {
        List<dynamic> trackData = result['data'];
        
        for (var t in trackData) {
          String hexColor = t['track_color'].replaceAll('#', '0xFF');
          Color tColor = Color(int.parse(hexColor));

          tracks.add(TrackItem(
            id: t['track_id'].toString(),
            name: t['instrument_name'],
            iconUrl: t['instrument_icon'] ?? '',
            audioUrl: baseAudioUrl + t['audio_file'],
            color: tColor,
            player: AudioPlayer(),
          ));
        }

        await _setupAudioPlayers();
        await _loadSavedPosition(); 
        
      } else {
        debugPrint("Error loading tracks: ${result['message']}");
      }
    } catch (e) {
        debugPrint("Exception in _initData: $e");
    } finally {
       if(mounted){
         setState(() {
           isLoading = false;
         });
       }
    }
  }

  Future<void> _setupAudioPlayers() async {
    for (int i = 0; i < tracks.length; i++) {
      try {
        await tracks[i].player.setSourceUrl(tracks[i].audioUrl);
        tracks[i].isLoaded = true;
        
        if (i == 0) {
          tracks[i].player.onDurationChanged.listen((duration) {
            setState(() => totalDuration = duration);
          });
          tracks[i].player.onPositionChanged.listen((position) {
            setState(() => currentPosition = position);
          });
          tracks[i].player.onPlayerComplete.listen((event) {
            _stopMusic(); 
          });
        }
      } catch (e) {
        debugPrint("❌ Failed to load audio for track ${tracks[i].name}. URL: ${tracks[i].audioUrl}");
        tracks[i].isLoaded = false;
      }
    }
  }

  Future<void> _loadSavedPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedMillis = prefs.getInt('saved_position_$songId');
    if (savedMillis != null && savedMillis > 0) {
      currentPosition = Duration(milliseconds: savedMillis);
      for (var t in tracks) {
        if(t.isLoaded) await t.player.seek(currentPosition);
      }
    }
  }

  Future<void> _savePosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_position_$songId', currentPosition.inMilliseconds);
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      for (var t in tracks) { 
          if(t.isLoaded) await t.player.pause(); 
      }
      await _savePosition(); 
    } else {
      for (var t in tracks) { 
        if(t.isLoaded){
             await t.player.setVolume(t.isMuted ? 0.0 : 1.0);
             await t.player.resume(); 
        }
      }
    }
    setState(() { isPlaying = !isPlaying; });
  }

  void _stopMusic() async {
    for (var t in tracks) { 
        if(t.isLoaded) await t.player.stop(); 
    }
    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_position_$songId');
  }

  void _seekMusic(double value) async {
    final position = Duration(milliseconds: value.toInt());
    for (var t in tracks) {
      if(t.isLoaded) await t.player.seek(position);
    }
  }

  void _toggleMute(TrackItem track) {
    setState(() {
      track.isMuted = !track.isMuted;
      if (isPlaying && track.isLoaded) {
        track.player.setVolume(track.isMuted ? 0.0 : 1.0);
      }
    });
  }

  @override
  void dispose() {
    _savePosition(); 
    for (var t in tracks) { t.player.dispose(); }
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 📌 เพิ่มโค้ดดักค่าเพื่อป้องกัน Slider Error (ค่า max/value ขัดแย้งกันตอนโหลดหน้า)
    double sliderMax = totalDuration.inMilliseconds.toDouble();
    if (sliderMax <= 0) sliderMax = 1.0; // ป้องกัน max เป็น 0

    double sliderValue = currentPosition.inMilliseconds.toDouble();
    if (sliderValue < 0) sliderValue = 0.0;
    if (sliderValue > sliderMax) sliderValue = sliderMax; // ป้องกัน value เกิน max

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // ปรับพื้นหลังให้เข้มขึ้นเหมือนโปรแกรมทำเพลง
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(songTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 30),
            onPressed: () => _seekMusic(0), 
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 40),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 36),
            onPressed: _stopMusic,
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tracks.isEmpty 
              ? const Center(child: Text("ไม่พบข้อมูลแทร็ก", style: TextStyle(color: Colors.white)))
              : Column(
              children: [
                // Timeline Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 8.0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.redAccent,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      min: 0,
                      max: sliderMax,
                      value: sliderValue,
                      onChanged: (value) {
                        _seekMusic(value);
                      },
                    ),
                  ),
                ),

                // Track List
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      var track = tracks[index];
                      // เงื่อนไข: ถ้าปิดแทร็ก ให้ใช้สีเทาเข้ม ถ้าเปิดให้ใช้สีจาก DB
                      Color trackBgColor = track.isMuted ? const Color(0xFF4A4A4A) : track.color;

                      return Container(
                        height: 70, // ปรับความสูงแทร็กให้วาดรูปคลื่นได้สวยขึ้น
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: 1)),
                        ),
                        child: Row(
                          children: [
                            // 1. ปุ่ม Mute และ Icon (ซ้าย)
                            GestureDetector(
                              onTap: () => _toggleMute(track),
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF383838), // สีพื้นหลังไอคอน
                                  border: Border(
                                    right: BorderSide(color: Colors.black.withOpacity(0.6), width: 2),
                                  )
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        track.iconUrl.isNotEmpty
                                          ? Image.network(baseImageUrl + track.iconUrl, height: 40, errorBuilder: (c,e,s) => const Icon(Icons.music_note, color: Colors.white70))
                                          : const Icon(Icons.music_note, color: Colors.white70, size: 30),
                                      ],
                                    ),
                                    // กากบาทสีแดงเมื่อ Muted
                                    if (track.isMuted)
                                      const Icon(Icons.close, color: Colors.redAccent, size: 60),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 2. แทร็กแถบสี และ Waveform (ขวา)
                            Expanded(
                              child: Container(
                                color: trackBgColor, // แถบสียาว (เป็นสีเทาถ้า Mute)
                                child: CustomPaint(
                                  size: const Size(double.infinity, double.infinity),
                                  painter: WaveformPainter(
                                    progress: sliderMax > 1 ? (sliderValue / sliderMax) : 0.0, // 📌 ใช้ค่าที่ดักความปลอดภัยแล้ว
                                    seed: track.id.hashCode, // ใช้ ID เป็นตัวสร้างความคลื่นให้คงที่
                                    isMuted: track.isMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

// วาดรูปคลื่นเสมือนจริง
class WaveformPainter extends CustomPainter {
  final double progress;
  final int seed;
  final bool isMuted;

  WaveformPainter({
    required this.progress, 
    required this.seed,
    required this.isMuted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var random = Random(seed); // ใช้ seed เดิมเสมอ คลื่นจะไม่ดิ้นไปมาตอน setState
    
    // สีของคลื่นส่วนที่ "เล่นผ่านไปแล้ว"
    Paint playedPaint = Paint()
      ..color = isMuted ? Colors.grey[400]! : Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // สีของคลื่นส่วนที่ "ยังไม่ได้เล่น"
    Paint unplayedPaint = Paint()
      ..color = isMuted ? Colors.grey[500]! : Colors.black.withOpacity(0.25)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double midY = size.height / 2;
    double currentX = size.width * progress;

    // วาดเส้นคลื่น (ความถี่)
    for (double x = 0; x < size.width; x += 5) {
      // สุ่มความสูงของเส้นคลื่น (10% - 80% ของความสูง Container)
      double heightPercent = 0.1 + random.nextDouble() * 0.7;
      double h = size.height * heightPercent;

      // เลือกสีเส้น (ถ้า x น้อยกว่าตำแหน่งปัจจุบัน แสดงว่าเล่นผ่านแล้ว)
      Paint p = x <= currentX ? playedPaint : unplayedPaint;
      
      canvas.drawLine(Offset(x, midY - h / 2), Offset(x, midY + h / 2), p);
    }

    // วาดเส้นแนวตั้ง (Playhead) ตำแหน่งที่กำลังเล่น
    Paint playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(currentX, 0), Offset(currentX, size.height), playheadPaint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isMuted != isMuted;
  }
}