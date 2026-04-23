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

  final String baseImageUrl = "http://127.0.0.1/ThaiMusic_Admin/uploads/images/";
  final String baseAudioUrl = "http://127.0.0.1/ThaiMusic_Admin/uploads/audio/";

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
        debugPrint("Attempting to load: ${tracks[i].audioUrl}");
        
        // 📌 Use setSourceUrl instead of direct play to preload
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
        // 📌 Log the exact URL that failed
        debugPrint("❌ Failed to load audio for track ${tracks[i].name}. URL: ${tracks[i].audioUrl}");
        debugPrint("Error details: $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100.0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.redAccent,
                    ),
                    child: Slider(
                      min: 0,
                      max: totalDuration.inMilliseconds.toDouble() > 0 ? totalDuration.inMilliseconds.toDouble() : 1,
                      value: currentPosition.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _seekMusic(value);
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      var track = tracks[index];
                      double opacity = track.isMuted ? 0.3 : 1.0;

                      return Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleMute(track),
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3E3E3E),
                                  border: Border(
                                    right: BorderSide(color: Colors.grey[800]!, width: 2),
                                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                                  )
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        track.iconUrl.isNotEmpty
                                          ? Image.network(baseImageUrl + track.iconUrl, height: 35, errorBuilder: (c,e,s) => const Icon(Icons.music_note, color: Colors.white))
                                          : const Icon(Icons.music_note, color: Colors.white),
                                      ],
                                    ),
                                    if (track.isMuted)
                                      const Icon(Icons.close, color: Colors.red, size: 50),
                                  ],
                                ),
                              ),
                            ),
                            
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: opacity, 
                                child: Container(
                                  color: track.color, 
                                  child: CustomPaint(
                                    painter: WaveformPainter(
                                      progress: currentPosition.inMilliseconds / (totalDuration.inMilliseconds == 0 ? 1 : totalDuration.inMilliseconds),
                                    ),
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

class WaveformPainter extends CustomPainter {
  final double progress;
  WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2;
    
    for (double i = 0; i < size.width; i += 10) {
      double height = (i % 30 == 0) ? size.height * 0.6 : size.height * 0.3;
      canvas.drawLine(
        Offset(i, (size.height - height) / 2), 
        Offset(i, (size.height + height) / 2), 
        linePaint
      );
    }

    Paint progressPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5;
    double currentX = size.width * progress;
    canvas.drawLine(Offset(currentX, 0), Offset(currentX, size.height), progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}