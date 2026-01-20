import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';
import '../../models/artist.dart';

class ArtistDialog extends StatefulWidget {
  final DatabaseService db;
  final Artist? artist;
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
  String? contentType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!.name;
      _loadExistingImage();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingImage() async {
    if (widget.artist?.artistProfileUrl != null) {
      try {
        final response = await http.get(Uri.parse(widget.artist!.artistProfileUrl!));
        if (response.statusCode == 200 && mounted) {
          setState(() {
            selectedImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        debugPrint("Error loading existing image: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final fileName = result.files.single.name;
      String? detectedContentType;
      final extension = fileName.split('.').last.toLowerCase();
      detectedContentType = (extension == 'jpg' || extension == 'jpeg') ? 'image/jpeg' : 'image/png';

      setState(() {
        selectedImageBytes = result.files.single.bytes;
        selectedFileName = fileName;
        contentType = detectedContentType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.artist == null ? "Add Artist" : "Edit Artist",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Artist Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Artist Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                   
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter artist name" : null,
                ),
                const SizedBox(height: 16),

                // Pick Image Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Artist Image"),
                  onPressed: _isSaving ? null : _pickImage,
                ),
                if (selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      selectedFileName!,
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),

                // Image Preview
                if (selectedImageBytes != null)
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
                        child: Image.memory(
                          selectedImageBytes!,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _isSaving ? null : _saveArtist,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.artist == null ? "Add" : "Update"),
        ),
      ],
    );
  }

  Future<void> _saveArtist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.artist == null) {
        await widget.db.addArtist(
          name: nameController.text,
          bio: bioController.text,
          about: aboutController.text,
          imageBytes: selectedImageBytes,
          contentType: contentType,
        );
      } else {
        await widget.db.updateArtist(
          artistId: widget.artist!.id,
          name: nameController.text,
          bio: bioController.text,
          about: aboutController.text,
          newImageBytes: selectedImageBytes,
          contentType: contentType,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
