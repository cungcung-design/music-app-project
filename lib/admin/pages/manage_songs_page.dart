import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../utils/toast.dart';
import '../widgets/songs_dialog.dart';

class ManageSongsPage extends StatefulWidget {
  const ManageSongsPage({super.key});

  @override
  State<ManageSongsPage> createState() => _ManageSongsPageState();
}

class _ManageSongsPageState extends State<ManageSongsPage> {
  final DatabaseService db = DatabaseService();
  final AudioPlayerService playerService = AudioPlayerService();

  List<Song> songs = [];
  List<Artist> artists = [];
  List<Album> albums = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAll();

    playerService.player.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final dbSongs = await db.getSongsWithDetails();
    final dbArtists = await db.getArtists();
    final dbAlbums = await db.getAlbums();

    setState(() {
      songs = dbSongs;
      artists = dbArtists;
      albums = dbAlbums;
      loading = false;
    });
  }

  void _startPlayback(Song song) async {
    if (song.audioUrl == null) return;
    playerService.setPlaylist(songs);
    playerService.playSong(song);
    setState(() {});
  }

  // --- CRUD ACTIONS ---
  Future<void> _deleteSong(String id) async {
    try {
      await db.deleteSong(id);
      showToast(context, "Song deleted successfully");
      loadAll();
    } catch (e) {
      showToast(context, "Failed to delete song", isError: true);
    }
  }

  void _showSongDialog({Song? song}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => SongDialog(db: db, song: song),
    );
    if (result == true) {
      loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showSongDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView.builder(
              padding:
                  const EdgeInsets.only(bottom: 120), // List ends above player
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isPlaying = playerService.currentSong?.id == song.id;

                return ListTile(
                  leading: Icon(
                    isPlaying ? Icons.graphic_eq : Icons.music_note,
                    color: isPlaying ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    song.name,
                    style: TextStyle(
                        color: isPlaying ? Colors.green : Colors.white),
                  ),
                  subtitle: Text(song.artistName ?? "",
                      style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showSongDialog(song: song)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSong(song.id)),
                    ],
                  ),
                  onTap: () => _startPlayback(song),
                );
              },
            ),
    );
  }
}
