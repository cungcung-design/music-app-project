import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';

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
  final TextEditingController artistIdController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.album != null) {
      nameController.text = widget.album!.name;
      artistIdController.text = widget.album!.artistId;
      coverUrlController.text = widget.album!.coverUrl ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(widget.album == null ? "Add Album" : "Edit Album", style: const TextStyle(color: Colors.white)),
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
                  decoration: const InputDecoration(hintText: 'Album Name', hintStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val!.isEmpty ? "Enter album name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: artistIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Artist ID', hintStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val!.isEmpty ? "Enter artist ID" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: coverUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Cover URL', hintStyle: TextStyle(color: Colors.grey)),
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
              if (widget.album == null) {
                await widget.db.addAlbum(
                  name: nameController.text,
                  artistId: artistIdController.text,
                  coverUrl: coverUrlController.text,
                );
              } else {
                await widget.db.updateAlbum(
                  id: widget.album!.id,
                  name: nameController.text,
                  artistId: artistIdController.text,
                  coverUrl: coverUrlController.text,
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
