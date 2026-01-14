import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../services/database_service.dart';
import '../widgets/audioplyer.dart'; // Your AudioPlayerService
import 'manage_songs_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final Album album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final AudioPlayerService _audio = AudioPlayerService();
  final DatabaseService _db = DatabaseService();

  late Future<List<Song>> _songsFuture;
  List<Song> _albumSongs = [];
  Song? _currentSong;

  // Map to store durations of songs
  Map<String, Duration> _songDurations = {};

  @override
  void initState() {
    super.initState();
    _songsFuture = _db.getSongsWithDetails();
    _refreshLocalList();

    // Listen for player state changes to update Play/Pause icons
    _audio.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
  }

  void _refreshLocalList() async {
    final songs = await _songsFuture;
    setState(() {
      _albumSongs = songs.where((s) => s.albumId == widget.album.id).toList();
    });
  }

  Future<void> _fullRefresh() async {
    final updatedSongs = await _db.getSongsWithDetails();
    setState(() {
      _albumSongs = updatedSongs
          .where((s) => s.albumId == widget.album.id)
          .toList();
    });
  }

  // Fetch duration of a song
  Future<void> _fetchSongDuration(Song song) async {
    if (song.audioUrl == null) return;
    try {
      final AudioPlayer tempPlayer = AudioPlayer();
      await tempPlayer.setSourceUrl(Uri.encodeFull(song.audioUrl!));
      final duration = await tempPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _songDurations[song.id] = duration;
        });
      }
      await tempPlayer.dispose();
    } catch (e) {
      print("Failed to get duration: $e");
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _audio.player.state == PlayerState.playing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.album.name,
          style: const TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest, color: Colors.green),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageSongsPage()),
              );
              _fullRefresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Header Section
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                widget.album.albumProfileUrl ?? '',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 220, color: Colors.grey[900]),
              ),
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "${_albumSongs.length} Tracks",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // 2. Song List (Duration Subtitle Removed)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _albumSongs.length,
              itemBuilder: (context, index) {
                final song = _albumSongs[index];
                final bool isThisSelected = _currentSong?.id == song.id;

                return ListTile(
                  leading: Text(
                    "${index + 1}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  title: Text(
                    song.name,
                    style: TextStyle(
                      color: isThisSelected ? Colors.green : Colors.white,
                      fontWeight: isThisSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  // SUBTITLE REMOVED HERE
                  trailing: Icon(
                    isThisSelected && isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: isThisSelected ? Colors.green : Colors.white54,
                    size: 30,
                  ),
                  onTap: () {
                    if (song.audioUrl != null) {
                      _audio.play(Uri.encodeFull(song.audioUrl!));
                      setState(() => _currentSong = song);
                    }
                  },
                );
              },
            ),
          ),

          // 3. Mini Player
          if (_currentSong != null) _buildMiniPlayer(isPlaying),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(bool isPlaying) {
    return Container(
      height: 120, // Increased height to fit the progress bar
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // 1. DURATION LINE (SEEK BAR)
          StreamBuilder<Duration>(
            stream: _audio.player.onPositionChanged,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _audio.player.onDurationChanged,
                builder: (context, snapshotDuration) {
                  final duration = snapshotDuration.data ?? Duration.zero;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                        ),
                        child: Slider(
                          activeColor: Colors.green,
                          inactiveColor: Colors.white24,
                          value: position.inMilliseconds.toDouble().clamp(
                            0.0,
                            duration.inMilliseconds.toDouble() > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                          ),
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (v) {
                            _audio.player.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                          },
                        ),
                      ),
                      // Time Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // 2. PLAYER CONTROLS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.album.albumProfileUrl ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSong!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          "Now Playing",
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      isPlaying
                          ? _audio.player.pause()
                          : _audio.player.resume();
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () {
                      _audio.stop();
                      setState(() => _currentSong = null);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
