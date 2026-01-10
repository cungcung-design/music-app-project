import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';
import '../../models/artist.dart';

class ArtistDialog extends StatefulWidget {
  final DatabaseService db;
  final Artist? artist; // null = Add, non-null = Edit
  const ArtistDialog({super.key, required this.db, this.artist});

  @override
  State<ArtistDialog> createState() => _ArtistDialogState();
}

class _ArtistDialogState extends State<ArtistDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController artistProfilePathController =
      TextEditingController(); // Supabase path
  final TextEditingController urlController = TextEditingController();

  bool _isUploading = false;
  bool _useUrl = false; // Toggle between file upload and URL input

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!.name;
      bioController.text = widget.artist!.bio ?? '';
      aboutController.text = widget.artist!.about ?? '';
      final profilePath = widget.artist!.artistProfilePath ?? '';
      artistProfilePathController.text = profilePath;

      if (profilePath.startsWith('http')) {
        _useUrl = true;
      }
    }
  }

  // -------------------- Pick & Upload from Laptop --------------------
  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final oldPath = artistProfilePathController.text.isNotEmpty
            ? artistProfilePathController.text
            : null;

        final uploadedPath = await widget.db.uploadArtistProfile(
          file,
          oldPath: oldPath,
        );

        artistProfilePathController.text = uploadedPath;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  // -------------------- Upload from URL --------------------
  Future<void> _handleUrlInput() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a URL')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Save to temp file
        final tempDir = Directory.systemTemp;
        final fileName =
            'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(response.bodyBytes);

        final oldPath = artistProfilePathController.text.isNotEmpty
            ? artistProfilePathController.text
            : null;

        final uploadedPath = await widget.db.uploadArtistProfile(
          tempFile,
          oldPath: oldPath,
        );

        artistProfilePathController.text = uploadedPath;

        // Delete temp file
        await tempFile.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded from URL successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download image from URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        widget.artist == null ? "Add Artist" : "Edit Artist",
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ---------------- Name ----------------
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Artist Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter artist name" : null,
                ),
                const SizedBox(height: 12),

                // ---------------- Bio ----------------
                TextFormField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Bio',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // ---------------- About ----------------
                TextFormField(
                  controller: aboutController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'About',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // ---------------- Toggle Upload ----------------
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _useUrl = false),
                      child: Text(
                        'Upload File',
                        style: TextStyle(
                          color: !_useUrl ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _useUrl = true),
                      child: Text(
                        'Use URL',
                        style: TextStyle(
                          color: _useUrl ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ---------------- File Upload ----------------
                if (!_useUrl)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: artistProfilePathController,
                          style: const TextStyle(color: Colors.white),
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Artist Profile Path',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Upload Image'),
                      ),
                    ],
                  ),

                // ---------------- URL Upload ----------------
                if (_useUrl)
                  Column(
                    children: [
                      TextFormField(
                        controller: urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter Image URL',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _handleUrlInput,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Upload from URL'),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // ---------------- Image Preview ----------------
                if (artistProfilePathController.text.isNotEmpty)
                  Image.network(
                    widget.db.getStorageUrl(
                      artistProfilePathController.text,
                      'artist_profiles',
                    )!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
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
              if (widget.artist == null) {
                await widget.db.addArtist(
                  name: nameController.text,
                  bio: bioController.text,
                  artistProfilePath: artistProfilePathController.text,
                  about: aboutController.text,
                );
              } else {
                await widget.db.updateArtist(
                  id: widget.artist!.id,
                  name: nameController.text,
                  bio: bioController.text,
                  artistProfilePath: artistProfilePathController.text,
                  about: aboutController.text,
                );
              }
              Navigator.pop(context, true);
            }
          },
          child: Text(widget.artist == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
