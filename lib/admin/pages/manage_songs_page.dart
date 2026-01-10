import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
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

  List<Song> songs = [];
  List<Artist> artists = [];
  List<Album> albums = [];

  bool loading = true;
  Song? currentlyPlayingSong;

  @override
  void initState() {
    super.initState();
    loadAll();

    // Reset currentlyPlayingSong when audio finishes
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() => currentlyPlayingSong = null);
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final fetchedSongs = await db.getSongsWithDetails();
    final fetchedArtists = await db.getArtists();
    final fetchedAlbums = await db.getAlbums();

    if (mounted) {
      setState(() {
        songs = fetchedSongs;
        artists = fetchedArtists;
        albums = fetchedAlbums;
        loading = false;
      });
    }
  }

  Future<void> playPauseSong(Song song) async {
    try {
      // If this song is already playing, pause it
      if (currentlyPlayingSong?.id == song.id &&
          audioPlayer.state == PlayerState.playing) {
        await audioPlayer.pause();
        setState(() => currentlyPlayingSong = null);
        return;
      }

      // Play new song instantly
      await audioPlayer.setSourceUrl(song.audioUrl ?? '');
      await audioPlayer.resume();
      setState(() => currentlyPlayingSong = song);
    } catch (e) {
      showToast(context, "Audio error: $e", isError: true);
    }
  }

  void showSongForm({Song? song}) {
    final nameController = TextEditingController(text: song?.name ?? '');
    String? selectedArtistId = song?.artistId;
    String? selectedAlbumId = song?.albumId;
    File? selectedAudio;
    String? audioFileName = song?.audioUrl?.split('/').last;

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
                _buildTextField(nameController),
                const SizedBox(height: 12),
                _buildDropdown(
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
                  label: "Select Artist",
                  onChanged: (value) =>
                      setState(() => selectedArtistId = value),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  value: selectedAlbumId,
                  items: albums
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
                  label: "Select Album",
                  onChanged: (value) => setState(() => selectedAlbumId = value),
                ),
                const SizedBox(height: 12),
                _buildAudioPicker(setState, (file, name) {
                  selectedAudio = file;
                  audioFileName = name;
                }),
                if (audioFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Selected: $audioFileName",
                      style: const TextStyle(color: Colors.white),
                    ),
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
                await _saveSong(
                  song,
                  nameController.text.trim(),
                  selectedArtistId,
                  selectedAlbumId,
                  selectedAudio,
                );
                Navigator.pop(context);
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

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Song Name',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
      ),
      dropdownColor: Colors.grey[800],
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildAudioPicker(
    StateSetter setState,
    Function(File, String) onFilePicked,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );
        if (result != null && result.files.single.path != null) {
          File file = File(result.files.single.path!);
          setState(() => onFilePicked(file, result.files.single.name));
        }
      },
      icon: const Icon(Icons.audiotrack),
      label: const Text("Pick Audio File"),
    );
  }

  Future<void> _saveSong(
    Song? song,
    String name,
    String? artistId,
    String? albumId,
    File? audioFile,
  ) async {
    if (name.isEmpty || artistId == null || albumId == null) {
      showToast(context, "Name, artist, and album are required", isError: true);
      return;
    }

    if (song == null && audioFile == null) {
      showToast(context, "Audio file is required for new songs", isError: true);
      return;
    }

    try {
      String? audioUrl;

      if (audioFile != null) {
        audioUrl = await db.uploadSongAudio(audioFile);
      } else if (song != null) {
        audioUrl = song.audioUrl;
      }

      if (song != null && audioUrl == null) {
        showToast(
          context,
          "Cannot edit song: audio data is missing",
          isError: true,
        );
        return;
      }

      if (song == null) {
        await db.addSong(
          name: name,
          artistId: artistId,
          albumId: albumId,
          audioUrl: audioUrl!,
        );
        showToast(context, "Song added ");
      } else {
        await db.updateSong(
          id: song.id,
          name: name,
          artistId: artistId,
          albumId: albumId,
          audioUrl: audioUrl!,
        );
        showToast(context, "Song updated ");
      }

      loadAll();
    } catch (e) {
      showToast(context, "Operation failed: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );

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
              albumProfilePath: '',
              albumProfileUrl: '',
            ),
          );

          final isPlaying = currentlyPlayingSong?.id == song.id;

          return Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            artist.artistProfileUrl != null &&
                                artist.artistProfileUrl!.isNotEmpty
                            ? Image.network(
                                artist.artistProfileUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[700],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[700],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${artist.name} • ${album.name}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isPlaying) ...[
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: Colors.green,
                                  inactiveTrackColor: Colors.grey,
                                  thumbColor: Colors.green,
                                ),
                                child: StreamBuilder<Duration>(
                                  stream: audioPlayer.onPositionChanged,
                                  builder: (context, snapshot) {
                                    final pos = snapshot.data ?? Duration.zero;
                                    return FutureBuilder<Duration?>(
                                      future: audioPlayer.getDuration(),
                                      builder: (context, durationSnapshot) {
                                        final total =
                                            durationSnapshot.data ??
                                            Duration(seconds: 1);
                                        return Slider(
                                          value: pos.inSeconds.toDouble().clamp(
                                            0,
                                            total.inSeconds.toDouble(),
                                          ),
                                          max: total.inSeconds.toDouble(),
                                          onChanged: (value) =>
                                              audioPlayer.seek(
                                                Duration(
                                                  seconds: value.toInt(),
                                                ),
                                              ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.green,
                        ),
                        onPressed: song.audioUrl != null
                            ? () => playPauseSong(song)
                            : null,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => showSongForm(song: song),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => deleteSong(song.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
