import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
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
  final AudioPlayer audioPlayer = AudioPlayer();
  final Uuid uuid = Uuid();

  List<Song> songs = [];
  List<Artist> artists = [];
  List<Album> albums = [];

  bool loading = true;
  Song? currentlyPlayingSong;

  @override
  void initState() {
    super.initState();
    loadAll();

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() => currentlyPlayingSong = null);
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  /// ================= LOAD DATA =================
  Future<void> loadAll() async {
    setState(() => loading = true);

    final dbSongs = await db.getSongsWithDetails();
    final dbArtists = await db.getArtists();
    final dbAlbums = await db.getAlbums();
    final storageSongs = await db.fetchSongsFromStorage();

    final dbSongIds = dbSongs.map((s) => s.id).toSet();

    // Convert storage-only songs to Song objects
    final storageOnlySongs = storageSongs
        .where((s) => !dbSongIds.contains(s.id))
        .map(
          (s) => Song(
            id: s.id,
            name: s.name,
            artistId: '',
            albumId: '',
            audioUrl: s.url,
            artistName: 'Storage Only',
            albumImage: null,
          ),
        )
        .toList();

    if (!mounted) return;

    setState(() {
      songs = [...dbSongs, ...storageOnlySongs];
      artists = dbArtists;
      albums = dbAlbums;
      loading = false;
    });
  }

  /// ================= PLAY / PAUSE =================
  Future<void> playPauseSong(Song song) async {
    try {
      if (currentlyPlayingSong?.id == song.id &&
          audioPlayer.state == PlayerState.playing) {
        await audioPlayer.pause();
        setState(() => currentlyPlayingSong = null);
        return;
      }

      if (song.audioUrl == null) {
        showToast(context, "Audio not found", isError: true);
        return;
      }

      await audioPlayer.setSourceUrl(song.audioUrl!);
      await audioPlayer.resume();
      setState(() => currentlyPlayingSong = song);
    } catch (e) {
      showToast(context, "Audio error: $e", isError: true);
    }
  }

  /// ================= ADD / EDIT SONG =================
  void showSongForm({Song? song}) {
    final nameController = TextEditingController(text: song?.name ?? '');
    String? selectedArtistId = song?.artistId;
    String? selectedAlbumId = song?.albumId;
    File? selectedAudio;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            song == null ? "Add Song" : "Edit Song",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _textField(nameController),
                const SizedBox(height: 12),
                _dropdown(
                  label: "Artist",
                  value: artists.any((a) => a.id == selectedArtistId)
                      ? selectedArtistId
                      : null,
                  items: artists,
                  getId: (a) => a.id,
                  getLabel: (a) => a.name,
                  onChanged: (v) => setStateDialog(() => selectedArtistId = v),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: "Album",
                  value: albums.any((a) => a.id == selectedAlbumId)
                      ? selectedAlbumId
                      : null,
                  items: albums,
                  getId: (a) => a.id,
                  getLabel: (a) => a.name,
                  onChanged: (v) => setStateDialog(() => selectedAlbumId = v),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.audiotrack),
                  label: const Text("Pick Audio"),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                    );
                    if (result != null && result.files.single.path != null) {
                      selectedAudio = File(result.files.single.path!);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                await saveSong(
                  song: song,
                  name: nameController.text.trim(),
                  artistId: selectedArtistId,
                  albumId: selectedAlbumId,
                  audioFile: selectedAudio,
                );
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveSong({
    Song? song, // null = add, not null = edit
    required String name,
    required String? artistId,
    required String? albumId,
    File? audioFile, // optional for edit
  }) async {
    // 1️⃣ Validate fields
    if (name.isEmpty || artistId == null || albumId == null) {
      showToast(context, "All fields required", isError: true);
      return;
    }

    try {
      // 2️⃣ Generate UUID if new song
      final String songId = song?.id ?? uuid.v4();

      // 3️⃣ Handle audio file upload
      String? audioUrl;

      if (audioFile != null) {
        // Upload new file and get URL
        audioUrl = await db.uploadSongAudio(file: audioFile);
      } else if (song != null) {
        // Keep existing audio URL
        audioUrl = song.audioUrl;
      }

      // 4️⃣ Audio is required if adding a new song
      if (song == null && audioUrl == null) {
        showToast(context, "Audio required", isError: true);
        return;
      }

      // 5️⃣ Add or Update
      if (song == null) {
        // ADD NEW SONG
        await db.addSong(
          id: songId,
          name: name.trim(),
          artistId: artistId,
          albumId: albumId,
          audioUrl: audioUrl!,
        );
        showToast(context, "Song added ✅");
      } else {
        // UPDATE EXISTING SONG
        // If it's a storage-only song (no artist/album), treat as add to DB
        if (song.artistId.isEmpty && song.albumId.isEmpty) {
          // Storage-only song: add to database with new UUID
          // Extract storage path from full URL
          String storagePath;
          if (audioUrl!.startsWith('http')) {
            final uri = Uri.parse(audioUrl!);
            storagePath = uri.pathSegments.last;
          } else {
            storagePath = audioUrl!;
          }

          await db.addSong(
            id: uuid.v4(), // Generate new UUID for database
            name: name.trim(),
            artistId: artistId,
            albumId: albumId,
            audioUrl: storagePath, // Store storage path, not full URL
          );
          showToast(context, "Storage song added to database ✅");
        } else {
          // Regular DB song: update
          await db.updateSong(
            id: song.id,
            name: name.trim(),
            artistId: artistId,
            albumId: albumId,
            audioUrl: audioUrl,
          );
          showToast(context, "Song updated ✅");
        }
      }

      // 6️⃣ Reload list
      await loadAll();
    } catch (e) {
      showToast(context, "Save failed: $e", isError: true);
    }
  }

  /// ================= DELETE =================
  Future<void> deleteSong(Song song) async {
    try {
      if (song.artistId.isEmpty && song.albumId.isEmpty) {
        // Storage-only song, delete from storage
        if (song.audioUrl != null) {
          final uri = Uri.parse(song.audioUrl!);
          final path = uri.pathSegments.last;
          await db.supabase.storage.from('song_audio').remove([path]);
          showToast(context, "Storage song deleted");
        }
      } else {
        // Database song
        await db.deleteSong(song.id);
        showToast(context, "Song deleted");
      }
      loadAll();
    } catch (e) {
      showToast(context, "Delete failed: $e", isError: true);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Songs"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadAll),
        ],
      ),
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
          final artist = artists.firstWhere(
            (a) => a.id == song.artistId,
            orElse: () => Artist(id: '', name: 'Unknown', bio: ''),
          );
          final album = albums.firstWhere(
            (a) => a.id == song.albumId,
            orElse: () => Album(
              id: '',
              name: 'Unknown',
              artistId: '',
              albumProfileUrl: '',
            ),
          );

          final isPlaying = currentlyPlayingSong?.id == song.id;

          return Card(
            color: Colors.grey[850],
            child: ListTile(
              leading: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.green,
              ),
              title: Text(
                song.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "${artist.name} • ${album.name}",
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () => playPauseSong(song),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showSongForm(song: song),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteSong(song),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _textField(TextEditingController c) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: "Song name",
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required String? value,
    required List<T> items,
    required String Function(T) getId,
    required String Function(T) getLabel,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.any((e) => getId(e) == value) ? value : null,
      dropdownColor: Colors.grey[800],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: getId(e),
              child: Text(
                getLabel(e),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
