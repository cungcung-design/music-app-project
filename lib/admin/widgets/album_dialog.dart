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
  final TextEditingController albumProfileUrlController =
      TextEditingController();

  List<Artist> artists = [];
  bool isLoading = true;
  String? selectedArtistId;
  File? selectedCoverFile;
  Uint8List? selectedCoverBytes;
  String? selectedFileName;
  bool removeCurrentCover = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
    if (widget.album != null) {
      nameController.text = widget.album!.name;
      selectedArtistId = widget.album!.artistId;
      albumProfileUrlController.text = widget.album!.albumProfileUrl ?? '';
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
      setState(() {
        isLoading = false;
      });
      // Handle error, maybe show a snackbar
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        selectedFileName = file.name;
        if (kIsWeb) {
          // Web: Use bytes
          selectedCoverBytes = file.bytes;
          selectedCoverFile = null;
        } else {
          // Mobile: Use file path
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
      title: Text(
        widget.album == null ? "Add Album" : "Edit Album",
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Album Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter album name" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedArtistId,
                  decoration: const InputDecoration(
                    hintText: 'Select Artist',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: artists.map((artist) {
                    return DropdownMenuItem<String>(
                      value: artist.id,
                      child: Text(
                        artist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedArtistId = value;
                    });
                  },
                  validator: (val) => val == null ? "Select an artist" : null,
                ),
                const SizedBox(height: 12),
                // Display current cover image when editing
                if (widget.album != null &&
                    widget.album!.albumProfileUrl != null &&
                    !removeCurrentCover)
                  Column(
                    children: [
                      const Text(
                        'Current Cover:',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          widget.album!.albumProfileUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            removeCurrentCover = true;
                            selectedCoverFile = null;
                            selectedCoverBytes = null;
                            selectedFileName = null;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Remove Cover',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ElevatedButton.icon(
                  onPressed: _pickCover,
                  icon: const Icon(Icons.image),
                  label: Text(
                    selectedFileName != null
                        ? "Selected: $selectedFileName"
                        : (widget.album != null &&
                              widget.album!.albumProfileUrl != null &&
                              !removeCurrentCover)
                        ? "Change Album Cover"
                        : "Pick Album Cover (Optional)",
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                if (widget.album == null) {
                  await widget.db.addAlbum(
                    name: nameController.text,
                    artistId: selectedArtistId!,
                    coverFile: selectedCoverFile,
                    coverBytes: selectedCoverBytes,
                  );
                  showToast(
                    context,
                    'Album added successfully',
                    isError: false,
                  );
                } else {
                  await widget.db.updateAlbum(
                    albumId: widget.album!.id,
                    name: nameController.text,
                    artistId: selectedArtistId!,
                    newCoverFile: selectedCoverFile,
                    newCoverBytes: selectedCoverBytes,
                    removeCurrentCover: removeCurrentCover,
                  );
                  showToast(
                    context,
                    'Album updated successfully',
                    isError: false,
                  );
                }
                Navigator.pop(context, true);
              } catch (e) {
                showToast(
                  context,
                  'Failed to ${widget.album == null ? "add" : "update"} album: $e',
                  isError: true,
                );
              }
            }
          },
          child: Text(widget.album == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
