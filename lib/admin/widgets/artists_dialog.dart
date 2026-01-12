import 'dart:io';
import 'dart:typed_data';
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

  Uint8List? selectedImageBytes;
  String? selectedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!.name;
      bioController.text = widget.artist!.bio ?? '';
      aboutController.text = widget.artist!.about ?? '';
      _loadExistingImage();
    }
  }

  Future<void> _loadExistingImage() async {
    if (widget.artist?.artistProfileUrl != null) {
      try {
        final response = await http.get(
          Uri.parse(widget.artist!.artistProfileUrl!),
        );
        if (response.statusCode == 200) {
          setState(() {
            selectedImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        // Handle error silently or log
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
        selectedFileName = result.files.single.name;
      });
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

                // ---------------- Image Upload ----------------
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Artist Image (Optional)"),
                ),
                if (selectedFileName != null)
                  Text(
                    "Selected: $selectedFileName",
                    style: const TextStyle(color: Colors.white),
                  ),

                const SizedBox(height: 12),

                // ---------------- Image Preview ----------------
                if (selectedImageBytes != null)
                  Container(
                    height: 120,
                    width: 120,
                    child: Image.memory(
                      selectedImageBytes!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      },
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
                if (widget.artist == null) {
                  await widget.db.addArtist(
                    name: nameController.text,
                    bio: bioController.text,
                    about: aboutController.text,
                    imageBytes: selectedImageBytes,
                  );
                } else {
                  await widget.db.updateArtist(
                    artistId: widget.artist!.id,
                    name: nameController.text,
                    bio: bioController.text,
                    about: aboutController.text,
                    newImageBytes: selectedImageBytes,
                  );
                }
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            }
          },
          child: Text(widget.artist == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
