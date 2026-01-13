import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../utils/toast.dart';

bool isValidUuid(String? id) {
  if (id == null || id.isEmpty) return false;
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(id);
}

class SongDialog extends StatefulWidget {
  final DatabaseService db;
  final Song? song; // null = Add, non-null = Edit

  const SongDialog({super.key, required this.db, this.song});

  @override
  State<SongDialog> createState() => _SongDialogState();
}

class _SongDialogState extends State<SongDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  List<Artist> artists = [];
  List<Album> albums = [];
  bool isLoading = true;

  String? selectedArtistId;
  String? selectedAlbumId;
  File? selectedAudio;

  final Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.song != null) {
      nameController.text = widget.song!.name;
      selectedArtistId = widget.song!.artistId;
      selectedAlbumId = widget.song!.albumId;
    }
  }

  Future<void> _loadData() async {
    try {
      final artistsData = await widget.db.getArtists();
      final albumsData = await widget.db.getAlbums();

      setState(() {
        artists = artistsData;
        albums = albumsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showToast(context, "Failed to load artists/albums: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        backgroundColor: Colors.grey,
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        widget.song == null ? "Add Song" : "Edit Song",
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Song Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Song Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter song name" : null,
                ),
                const SizedBox(height: 12),

                // Artist Dropdown
                DropdownButtonFormField<String>(
                  value: artists.any((a) => a.id == selectedArtistId)
                      ? selectedArtistId
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Select Artist',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: artists
                      .map(
                        (artist) => DropdownMenuItem<String>(
                          value: artist.id,
                          child: Text(
                            artist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedArtistId = value;
                    });
                  },
                  validator: (val) => val == null ? "Select an artist" : null,
                ),
                const SizedBox(height: 12),

                // Album Dropdown
                DropdownButtonFormField<String>(
                  value: albums.any((a) => a.id == selectedAlbumId)
                      ? selectedAlbumId
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Select Album',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: albums
                      .map(
                        (album) => DropdownMenuItem<String>(
                          value: album.id,
                          child: Text(
                            album.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAlbumId = value;
                    });
                  },
                  validator: (val) => val == null ? "Select an album" : null,
                ),
                const SizedBox(height: 12),

                // Pick Audio Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.audiotrack),
                  label: Text(
                    widget.song == null
                        ? "Pick Audio"
                        : "Change Audio (optional)",
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                    );
                    if (result != null && result.files.single.path != null) {
                      setState(() {
                        selectedAudio = File(result.files.single.path!);
                      });
                    }
                  },
                ),
                if (selectedAudio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Selected: ${selectedAudio!.path.split('/').last}",
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            if (widget.song == null && selectedAudio == null) {
              showToast(context, "Audio is required", isError: true);
              return;
            }

            String id = widget.song?.id ?? uuid.v4();
            String? audioUrl = widget.song?.audioUrl;

            if (selectedAudio != null) {
              audioUrl = await widget.db.uploadSongAudio(file: selectedAudio!);
            }

            if (widget.song == null || !isValidUuid(widget.song!.id)) {
              
              await widget.db.addSong(
                id: id,
                name: nameController.text.trim(),
                artistId: selectedArtistId!,
                albumId: selectedAlbumId!,
                audioUrl: audioUrl!,
              );
              showToast(context, "Song added ✅");
            } else {
              // Valid UUID, update existing song
              await widget.db.updateSong(
                id: widget.song!.id,
                name: nameController.text.trim(),
                artistId: selectedArtistId!,
                albumId: selectedAlbumId!,
                audioUrl: audioUrl!,
              );
              showToast(context, "Song updated ✅");
            }

            Navigator.pop(context, true); // return true to reload
          },
          child: Text(widget.song == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
