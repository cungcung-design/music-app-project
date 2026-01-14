import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../widgets/mini_player_buttom.dart';
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
  Song? currentlyPlayingSong;

  @override
  void initState() {
    super.initState();
    loadAll();

    // Player Listeners
    playerService.player.onPlayerStateChanged.listen((_) => setState(() {}));
    playerService.player.onPlayerComplete.listen((event) => playNext());
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
  void playNext() {
    if (songs.isEmpty) return;
    int currentIndex = songs.indexWhere(
      (s) => s.id == currentlyPlayingSong?.id,
    );
    int nextIndex = (currentIndex + 1) % songs.length;
    _startPlayback(songs[nextIndex]);
  }

  void playPrevious() {
    if (songs.isEmpty) return;
    int currentIndex = songs.indexWhere(
      (s) => s.id == currentlyPlayingSong?.id,
    );
    int prevIndex = (currentIndex - 1 < 0)
        ? songs.length - 1
        : currentIndex - 1;
    _startPlayback(songs[prevIndex]);
  }

  Future<void> _startPlayback(Song song) async {
    if (song.audioUrl == null) return;
    await playerService.player.stop();
    await playerService.player.play(UrlSource(song.audioUrl!));
    setState(() => currentlyPlayingSong = song);
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
          content: Column(
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
                items: artists
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          a.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedArtistId = v),
                decoration: const InputDecoration(
                  labelText: "Artist",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[850],
                value: selectedAlbumId,
                items: albums
                    .map(
                      (al) => DropdownMenuItem(
                        value: al.id,
                        child: Text(
                          al.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedAlbumId = v),
                decoration: const InputDecoration(
                  labelText: "Album",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              if (song == null) // Only for adding new song
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.audio);
                    if (result != null) {
                      setDialogState(
                        () => selectedFile = File(result.files.single.path!),
                      );
                    }
                  },
                  child: Text(
                    selectedFile != null
                        ? "Audio Selected: ${selectedFile!.path.split('/').last}"
                        : "Select Audio File",
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  showToast(
                    context,
                    "Song name cannot be empty",
                    isError: true,
                  );
                  return;
                }
                if (selectedArtistId == null || selectedArtistId!.isEmpty) {
                  showToast(context, "Please select an artist", isError: true);
                  return;
                }
                if (selectedAlbumId == null || selectedAlbumId!.isEmpty) {
                  showToast(context, "Please select an album", isError: true);
                  return;
                }
                try {
                  if (song == null) {
                    if (selectedFile == null) {
                      showToast(
                        context,
                        "Please select an audio file",
                        isError: true,
                      );
                      return;
                    }
                    final audioUrl = await db.uploadSongAudio(
                      file: selectedFile,
                    );
                    final id = db.uuid.v4();
                    await db.addSong(
                      id: id,
                      name: nameController.text.trim(),
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                      audioUrl: audioUrl,
                    );
                    showToast(context, "Song added successfully");
                  } else {
                    await db.updateSong(
                      id: song.id,
                      name: nameController.text.trim(),
                      artistId: selectedArtistId!,
                      albumId: selectedAlbumId!,
                    );
                    // Update local list immediately
                    setState(() {
                      final index = songs.indexWhere((s) => s.id == song.id);
                      if (index != -1) {
                        final newArtistName = artists
                            .firstWhere(
                              (a) => a.id == selectedArtistId,
                              orElse: () => Artist(id: '', name: '', bio: ''),
                            )
                            .name;
                        final newAlbumImage = albums
                            .firstWhere(
                              (al) => al.id == selectedAlbumId,
                              orElse: () =>
                                  Album(id: '', name: '', artistId: ''),
                            )
                            .albumProfileUrl;
                        songs[index] = songs[index].copyWith(
                          name: nameController.text.trim(),
                          artistId: selectedArtistId!,
                          albumId: selectedAlbumId!,
                          artistName: newArtistName,
                          albumImage: newAlbumImage,
                        );
                        // Update currently playing song if it's the same one
                        if (currentlyPlayingSong?.id == song.id) {
                          currentlyPlayingSong = songs[index];
                        }
                      }
                    });
                    showToast(context, "Song updated successfully");
                  }
                  Navigator.pop(context);
                } catch (e) {
                  showToast(
                    context,
                    song == null
                        ? "Failed to add song"
                        : "Failed to update song",
                    isError: true,
                  );
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

      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: currentlyPlayingSong != null ? 110 : 0,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () => _showSongForm(),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isPlaying = currentlyPlayingSong?.id == song.id;
                      return ListTile(
                        leading: Icon(
                          isPlaying ? Icons.graphic_eq : Icons.music_note,
                          color: isPlaying ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          song.name,
                          style: TextStyle(
                            color: isPlaying ? Colors.green : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          song.artistName ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSongForm(song: song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSong(song.id),
                            ),
                          ],
                        ),
                        onTap: () => _startPlayback(song),
                      );
                    },
                  ),
          ),
          if (currentlyPlayingSong != null)
            MiniPlayerWidget(
              song: currentlyPlayingSong!,
              playerService: playerService,
              onStop: () => setState(() {
                playerService.stopAndClear();
                currentlyPlayingSong = null;
              }),
              onNext: playNext,
              onPrevious: playPrevious,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    playerService.dispose();
    super.dispose();
  }
}
