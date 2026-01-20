import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../utils/toast.dart';

class AlbumDialog extends StatefulWidget {
  final DatabaseService db;
  final Album? album; // null = Add, non-null = Edit
  const AlbumDialog({super.key, required this.db, this.album});

  @override
  State<AlbumDialog> createState() => _AlbumDialogState();
}

class _AlbumDialogState extends State<AlbumDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  List<Artist> artists = [];
  bool isLoading = true;
  String? selectedArtistId;
  File? selectedCoverFile;
  Uint8List? selectedCoverBytes;
  String? selectedFileName;
  bool removeCurrentCover = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
    if (widget.album != null) {
      nameController.text = widget.album!.name;
      selectedArtistId = widget.album!.artistId;
    }
  }

  Future<void> _loadArtists() async {
    try {
      final artistsData = await widget.db.getArtists();
      setState(() {
        artists = artistsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showToast(context, "Failed to load artists: $e", isError: true);
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb, // Use bytes for web
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        selectedFileName = file.name;
        if (kIsWeb) {
          selectedCoverBytes = file.bytes;
          selectedCoverFile = null;
        } else {
          selectedCoverFile = File(file.path!);
          selectedCoverBytes = null;
        }
      });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.album == null ? "Add Album" : "Edit Album",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Album Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Album Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                  
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter album name" : null,
                ),
                const SizedBox(height: 16),

                // Artist Dropdown
                DropdownButtonFormField<String>(
                  value: selectedArtistId,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Select Artist',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: artists
                      .map((artist) => DropdownMenuItem(
                            value: artist.id,
                            child: Text(artist.name, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedArtistId = value),
                  validator: (val) => val == null ? "Select an artist" : null,
                ),
                const SizedBox(height: 16),

                // Current cover preview
                if (widget.album != null &&
                    widget.album!.albumProfileUrl != null &&
                    !removeCurrentCover)
                  Column(
                    children: [
                      const Text('Current Cover:', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.album!.albumProfileUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          removeCurrentCover = true;
                          selectedCoverBytes = null;
                          selectedCoverFile = null;
                          selectedFileName = null;
                        }),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remove Cover', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Pick cover button
                FilledButton.icon(
                  icon: const Icon(Icons.image),
                  label: Text(selectedFileName != null
                      ? "Selected: $selectedFileName"
                      : (widget.album != null &&
                              widget.album!.albumProfileUrl != null &&
                              !removeCurrentCover)
                          ? "Change Album Cover"
                          : "Pick Album Cover (Optional)"),
                  onPressed: _pickCover,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                if (selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Selected file: $selectedFileName',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
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
        FilledButton(
          onPressed: _isSaving ? null : _saveAlbum,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.album == null ? "Add" : "Update"),
        ),
      ],
    );
  }

  Future<void> _saveAlbum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.album == null) {
        await widget.db.addAlbum(
          name: nameController.text,
          artistId: selectedArtistId!,
          coverFile: selectedCoverFile,
          coverBytes: selectedCoverBytes,
        );
        showToast(context, 'Album added successfully', isError: false);
      } else {
        await widget.db.updateAlbum(
          albumId: widget.album!.id,
          name: nameController.text,
          artistId: selectedArtistId!,
          newCoverFile: selectedCoverFile,
          newCoverBytes: selectedCoverBytes,
          removeCurrentCover: removeCurrentCover,
        );
        showToast(context, 'Album updated successfully', isError: false);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showToast(
        context,
        'Failed to ${widget.album == null ? "add" : "update"} album: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
