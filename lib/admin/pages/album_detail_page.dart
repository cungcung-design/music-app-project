import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../services/database_service.dart';
import '../widgets/audioplyer.dart'; // Using your AudioPlayerService
import 'manage_songs_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final Album album;
  final List<Song> songs;
  final List<Artist> artists;

  const AlbumDetailPage({
    super.key,
    required this.album,
    required this.songs,
    required this.artists,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final AudioPlayerService _audio = AudioPlayerService();
  final DatabaseService _db = DatabaseService();
  
  late List<Song> _albumSongs;
  Song? _currentSong;

  @override
  void initState() {
    super.initState();
    _refreshLocalList();
    
    // Listen for player state changes to update the UI (Play/Pause icons)
    _audio.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
  }

  void _refreshLocalList() {
    setState(() {
      _albumSongs = widget.songs.where((s) => s.albumId == widget.album.id).toList();
    });
  }

  // Reloads data from Database (called after returning from ManageSongsPage)
  Future<void> _fullRefresh() async {
    final updatedSongs = await _db.getSongsWithDetails();
    setState(() {
      _albumSongs = updatedSongs.where((s) => s.albumId == widget.album.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _audio.player.state == PlayerState.playing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Colors.transparent,
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
          )
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
                errorBuilder: (_, __, ___) => Container(height: 220, color: Colors.grey[900]),
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
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // 2. Song List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _albumSongs.length,
              itemBuilder: (context, index) {
                final song = _albumSongs[index];
                final bool isThisSelected = _currentSong?.id == song.id;

                return ListTile(
                  leading: Text("${index + 1}", style: const TextStyle(color: Colors.grey)),
                  title: Text(
                    song.name,
                    style: TextStyle(
                      color: isThisSelected ? Colors.green : Colors.white,
                      fontWeight: isThisSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    isThisSelected && isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: isThisSelected ? Colors.green : Colors.white54,
                    size: 30,
                  ),
                  onTap: () {
                    _audio.play(song.audioUrl ?? '');
                    setState(() => _currentSong = song);
                  },
                );
              },
            ),
          ),

          // 3. Mini Player (Fixed Height to avoid 14px overflow)
          if (_currentSong != null) _buildMiniPlayer(isPlaying),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(bool isPlaying) {
    return Container(
      height: 90, // Strict height to prevent overflow
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              widget.album.albumProfileUrl ?? '',
              width: 50,
              height: 50,
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text("Now Playing", style: TextStyle(color: Colors.green, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
            onPressed: () {
              isPlaying ? _audio.player.pause() : _audio.player.resume();
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
    );
  }
}