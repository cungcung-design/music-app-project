import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isSaving = false;

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
      setState(() => isLoading = false);
      showToast(context, "Failed to load data: $e", isError: true);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedAudio = File(result.files.single.path!);
      });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.song == null ? "Add Song" : "Edit Song",
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Song Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Song Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter song name" : null,
                ),
                const SizedBox(height: 16),

                // Artist Dropdown
                DropdownButtonFormField<String>(
                  value: artists.any((a) => a.id == selectedArtistId)
                      ? selectedArtistId
                      : null,
                  dropdownColor: Colors.grey[800],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  hint: const Text("Select Artist",
                      style: TextStyle(color: Colors.grey)),
                  items: artists
                      .map((artist) => DropdownMenuItem(
                            value: artist.id,
                            child: Text(artist.name,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedArtistId = val),
                  validator: (val) => val == null ? "Select artist" : null,
                ),
                const SizedBox(height: 16),

                // Album Dropdown
                DropdownButtonFormField<String>(
                  value: albums.any((a) => a.id == selectedAlbumId)
                      ? selectedAlbumId
                      : null,
                  dropdownColor: Colors.grey[800],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  hint: const Text("Select Album",
                      style: TextStyle(color: Colors.grey)),
                  items: albums
                      .map((album) => DropdownMenuItem(
                            value: album.id,
                            child: Text(album.name,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedAlbumId = val),
                  validator: (val) => val == null ? "Select album" : null,
                ),
                const SizedBox(height: 16),

                // Pick Audio Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.audiotrack),
                  label: Text(
                    widget.song == null
                        ? "Pick Audio"
                        : "Change Audio (optional)",
                  ),
                  onPressed: _isSaving ? null : _pickAudio,
                ),

                // Audio name preview
                if (selectedAudio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      selectedAudio!.path.split('/').last,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Cancel button (always visible)
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),

        // Add / Update button
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _isSaving ? null : _submitSong,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(widget.song == null ? "Add" : "Update"),
        ),
      ],
    );
  }

  Future<void> _submitSong() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.song == null && selectedAudio == null) {
      showToast(context, "Audio is required", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String songId = widget.song?.id ?? uuid.v4();
      String? audioPath = widget.song?.audioUrl;

      if (selectedAudio != null) {
        audioPath = await widget.db.uploadSongAudio(file: selectedAudio!);
      }

      if (widget.song == null) {
        await widget.db.addSong(
          id: songId,
          name: nameController.text.trim(),
          artistId: selectedArtistId!,
          albumId: selectedAlbumId!,
          audioUrl: audioPath!,
        );
        showToast(context, "Song added ");
      } else {
        await widget.db.updateSong(
          id: widget.song!.id,
          name: nameController.text.trim(),
          artistId: selectedArtistId!,
          albumId: selectedAlbumId!,
          audioUrl: audioPath!,
        );
        showToast(context, "Song updated ");
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, "Failed to save song: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
