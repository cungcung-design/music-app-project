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

    // Listen to global player changes to refresh the "playing" icons in this list
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

  // --- PLAYBACK LOGIC ---
  void _startPlayback(Song song) async {
    if (song.audioUrl == null) return;
    // Set the full list as the playlist for Next/Prev support
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

  void _showSongForm({Song? song}) {
    final nameController = TextEditingController(text: song?.name ?? "");
    String? selectedArtistId = song?.artistId;
    String? selectedAlbumId = song?.albumId;
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            song == null ? "Add Song" : "Edit Song",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Song Name",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[850],
                  value: selectedArtistId,
                  items: artists.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedArtistId = v),
                  decoration: const InputDecoration(labelText: "Artist", labelStyle: TextStyle(color: Colors.grey)),
                ),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[850],
                  value: selectedAlbumId,
                  items: albums.map((al) => DropdownMenuItem(
                    value: al.id,
                    child: Text(al.name, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedAlbumId = v),
                  decoration: const InputDecoration(labelText: "Album", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 20),
                if (song == null)
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                      if (result != null) {
                        setDialogState(() => selectedFile = File(result.files.single.path!));
                      }
                    },
                    child: Text(selectedFile != null ? "Selected: ${selectedFile!.path.split('/').last}" : "Select Audio File"),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || selectedArtistId == null || selectedAlbumId == null) {
                  showToast(context, "Please fill all fields", isError: true);
                  return;
                }
                try {
                  if (song == null) {
                    if (selectedFile == null) return;
                    final audioUrl = await db.uploadSongAudio(file: selectedFile);
                    await db.addSong(
                      id: db.uuid.v4(),
                      name: nameController.text.trim(),
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                      audioUrl: audioUrl,
                    );
                  } else {
                    await db.updateSong(
                      id: song.id,
                      name: nameController.text.trim(),
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                    );
                  }
                  await loadAll();
                  Navigator.pop(context);
                  showToast(context, "Success!");
                } catch (e) {
                  showToast(context, "Error saving song", isError: true);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
    
      floatingActionButton: 
        FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () => _showSongForm(),
          child: const Icon(Icons.add, color: Colors.black),
        ),
    
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120), // List ends above player
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
                    style: TextStyle(color: isPlaying ? Colors.green : Colors.white),
                  ),
                  subtitle: Text(song.artistName ?? "", style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showSongForm(song: song)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSong(song.id)),
                    ],
                  ),
                  onTap: () => _startPlayback(song),
                );
              },
            ),
    );
  }
}