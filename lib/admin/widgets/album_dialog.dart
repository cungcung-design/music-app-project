import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';

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
  String? selectedFileName;

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

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedCoverFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
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
                ElevatedButton.icon(
                  onPressed: _pickCover,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Album Cover (Optional)"),
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
              if (widget.album == null) {
                await widget.db.addAlbum(
                  name: nameController.text,
                  artistId: selectedArtistId!,
                  coverFile: selectedCoverFile,
                );
              } else {
                await widget.db.updateAlbum(
                  albumId: widget.album!.id,
                  name: nameController.text,
                  artistId: selectedArtistId!,
                  newCoverFile: selectedCoverFile,
                );
              }
              Navigator.pop(context, true);
            }
          },
          child: Text(widget.album == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
