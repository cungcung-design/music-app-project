import 'package:flutter/material.dart';
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
  final TextEditingController profileUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!.name;
      bioController.text = widget.artist!.bio ?? '';
      profileUrlController.text = widget.artist!.profileUrl ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(widget.artist == null ? "Add Artist" : "Edit Artist", style: const TextStyle(color: Colors.white)),
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
                  decoration: const InputDecoration(hintText: 'Artist Name', hintStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val!.isEmpty ? "Enter artist name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Bio', hintStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: profileUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Profile URL', hintStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (widget.artist == null) {
                await widget.db.addArtist(
                  name: nameController.text,
                  bio: bioController.text,
                  profileUrl: profileUrlController.text,
                );
              } else {
                await widget.db.updateArtist(
                  id: widget.artist!.id,
                  name: nameController.text,
                  bio: bioController.text,
                  profileUrl: profileUrlController.text,
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
