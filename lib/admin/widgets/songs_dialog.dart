import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../utils/toast.dart';

class SongDialog extends StatefulWidget {
  final DatabaseService db;
  final Song? song;

  const SongDialog({super.key, required this.db, this.song});

  @override
  State<SongDialog> createState() => _SongDialogState();
}

class _SongDialogState extends State<SongDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  final Uuid uuid = const Uuid();

  List<Artist> artists = [];
  List<Album> albums = [];
  bool isLoading = true;

  String? selectedArtistId;
  String? selectedAlbumId;

  File? selectedAudio;

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
      isLoading = false;
      showToast(context, "Failed to load data: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
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
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ---------- SONG NAME ----------
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

                // ---------- ARTIST ----------
                DropdownButtonFormField<String>(
                  value: artists.any((a) => a.id == selectedArtistId)
                      ? selectedArtistId
                      : null,
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    hintText: 'Select Artist',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: artists
                      .map(
                        (artist) => DropdownMenuItem(
                          value: artist.id,
                          child: Text(
                            artist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    selectedArtistId = val;
                  }),
                  validator: (val) => val == null ? "Select artist" : null,
                ),
                const SizedBox(height: 12),

                // ---------- ALBUM ----------
                DropdownButtonFormField<String>(
                  value: albums.any((a) => a.id == selectedAlbumId)
                      ? selectedAlbumId
                      : null,
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    hintText: 'Select Album',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: albums
                      .map(
                        (album) => DropdownMenuItem(
                          value: album.id,
                          child: Text(
                            album.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    selectedAlbumId = val;
                  }),
                  validator: (val) => val == null ? "Select album" : null,
                ),
                const SizedBox(height: 12),

                // ---------- AUDIO PICK ----------
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      selectedAudio!.path.split('/').last,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.song != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              // Handle storage-only songs differently
              if (widget.song!.artistId.isEmpty && widget.song!.albumId.isEmpty) {
                // Storage-only song, delete from storage
                if (widget.song!.audioUrl != null) {
                  final uri = Uri.parse(widget.song!.audioUrl!);
                  final path = uri.pathSegments.last;
                  await widget.db.supabase.storage.from('song_audio').remove([path]);
                  showToast(context, "Storage song deleted");
                }
              } else {
                // Database song
                await widget.db.deleteSong(widget.song!.id);
                showToast(context, "Song deleted");
              }
              Navigator.pop(context, true);
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text(widget.song == null ? "Add" : "Update"),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            if (widget.song == null && selectedAudio == null) {
              showToast(context, "Audio is required", isError: true);
              return;
            }

            final String songId = widget.song?.id ?? uuid.v4();
            String? audioPath = widget.song?.audioUrl;

            if (selectedAudio != null) {
              audioPath = await widget.db.uploadSongAudio(file: selectedAudio!);
            }

            if (widget.song == null) {
              // ADD
              await widget.db.addSong(
                id: songId,
                name: nameController.text.trim(),
                artistId: selectedArtistId!,
                albumId: selectedAlbumId!,
                audioUrl: audioPath!,
              );
              showToast(context, "Song added ✅");
            } else {
             
              if (widget.song!.artistId.isEmpty &&
                  widget.song!.albumId.isEmpty) {
              
                await widget.db.addSong(
                  id: uuid.v4(), 
                  artistId: selectedArtistId!,
                  albumId: selectedAlbumId!,
                  audioUrl: audioPath!, 
                );
                showToast(context, "Storage song added to database ✅");
              } else {
               
                await widget.db.updateSong(
                  id: widget.song!.id,
                  name: nameController.text.trim(),
                  artistId: selectedArtistId!,
                  albumId: selectedAlbumId!,
                  audioUrl: audioPath!,
                );
                showToast(context, "Song updated ✅");
              }
            }

            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
