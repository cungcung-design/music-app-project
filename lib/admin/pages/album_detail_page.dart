import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player_buttom.dart';

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

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _songsFuture = _db.getSongsWithDetails();
    _refreshLocalList();

    // Listen for state changes globally so the play icons in the list update
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

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _audio.player.state == PlayerState.playing;
    final String? currentSongId = _audio.currentSong?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.album.name,
          style: const TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                widget.album.albumProfileUrl ?? '',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 240, color: Colors.grey[900]),
              ),
              Container(
                height: 120,
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
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          // Song List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 120,
              ), // Extra bottom padding for the mini player
              itemCount: _albumSongs.length,
              itemBuilder: (context, index) {
                final song = _albumSongs[index];
                final bool isThisSelected = currentSongId == song.id;

                return ListTile(
                  leading: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isThisSelected ? Colors.green : Colors.grey,
                    ),
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
                  trailing: Icon(
                    isThisSelected && isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: isThisSelected ? Colors.green : Colors.white54,
                    size: 30,
                  ),
                  onTap: () {
                    if (song.audioUrl != null) {
                      _audio.setPlaylist(_albumSongs);
                      _audio.playSong(song);
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),
          // Mini Player
          const GlobalMiniPlayer(),
        ],
      ),
    );
  }
}
