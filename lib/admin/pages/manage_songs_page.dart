import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
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
  List<Song> songs = [];
  List<Artist> artists = [];
  List<Album> albums = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final songsData = await db.getSongs();
    final artistsData = await db.getArtists();
    final albumsData = await db.getAlbums();
    if (mounted) {
      setState(() {
        songs = songsData;
        artists = artistsData;
        albums = albumsData;
        loading = false;
      });
    }
  }

  void showSongForm({Song? song}) {
    final nameController = TextEditingController(text: song?.name ?? '');
    String? selectedArtistId = song?.artistId;
    String? selectedAlbumId = song?.albumId;
    File? selectedAudio;
    String? audioFileName = song != null ? song.audioUrl?.split('/').last : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            song == null ? "Add Song" : "Edit Song",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Song name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Song Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                // Artist dropdown
                DropdownButtonFormField<String>(
                  value: selectedArtistId,
                  items: artists.map((artist) {
                    return DropdownMenuItem(
                      value: artist.id,
                      child: Text(artist.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedArtistId = value),
                  decoration: const InputDecoration(
                    labelText: 'Select Artist',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Album dropdown
                DropdownButtonFormField<String>(
                  value: selectedAlbumId,
                  items: albums.map((album) {
                    return DropdownMenuItem(
                      value: album.id,
                      child: Text(album.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedAlbumId = value),
                  decoration: const InputDecoration(
                    labelText: 'Select Album',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Pick audio
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                    if (result != null && result.files.single.path != null) {
                      selectedAudio = File(result.files.single.path!);
                      setState(() {
                        audioFileName = result.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.audiotrack),
                  label: const Text("Pick Audio File"),
                ),
                const SizedBox(height: 8),

                if (audioFileName != null)
                  Text(
                    "Selected: $audioFileName", // ✅ fixed, no .data or null error
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selectedArtistId == null || selectedAlbumId == null || (song == null && selectedAudio == null)) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }

                try {
                  String? audioPath = song?.audioUrl;

                  if (selectedAudio != null) {
                    // Upload audio to Supabase storage (song_audio bucket)
                    audioPath = await db.uploadSongAudio(selectedAudio!);
                  }

                  if (song == null) {
                    await db.addSong(
                      name: name,
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                      audioUrl: audioPath!,
                    );
                    showToast(context, "Song added ✅");
                  } else {
                    await db.updateSong(
                      id: song.id,
                      name: name,
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                      audioUrl: audioPath!,
                    );
                    showToast(context, "Song updated ✅");
                  }

                  Navigator.pop(context);
                  loadAll();
                } catch (e) {
                  showToast(context, "Operation failed: $e", isError: true);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteSong(String id) async {
    await db.deleteSong(id);
    showToast(context, "Song deleted ✅");
    loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showSongForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final song = songs[index];
          final artist = artists.firstWhere((a) => a.id == song.artistId, orElse: () => Artist(id: '', name: 'Unknown', bio: ''));
          final album = albums.firstWhere((a) => a.id == song.albumId, orElse: () => Album(id: '', name: 'Unknown', artistId: '', coverUrl: ''));

          return ListTile(
            tileColor: Colors.grey[850],
            leading: const Icon(Icons.music_note, color: Colors.green),
            title: Text(song.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'Artist: ${artist.name}\nAlbum: ${album.name}',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showSongForm(song: song),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteSong(song.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
