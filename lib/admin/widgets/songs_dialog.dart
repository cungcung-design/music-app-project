import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';

class SongDialog extends StatefulWidget {
  final DatabaseService db;
  final Song? song; // null = Add, non-null = Edit
  const SongDialog({super.key, required this.db, this.song});

  @override
  State<SongDialog> createState() => _SongDialogState();
}

class _SongDialogState extends State<SongDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController artistIdController = TextEditingController();
  final TextEditingController albumIdController = TextEditingController();
  final TextEditingController audioUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.song != null) {
      nameController.text = widget.song!.name;
      artistIdController.text = widget.song!.artistId;
      albumIdController.text = widget.song!.albumId;
      audioUrlController.text = widget.song!.audioUrl ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(widget.song == null ? "Add Song" : "Edit Song", style: const TextStyle(color: Colors.white)),
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
                  decoration: const InputDecoration(hintText: 'Song Name', hintStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val!.isEmpty ? "Enter song name" : null,
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
                  controller: albumIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Album ID', hintStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val!.isEmpty ? "Enter album ID" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: audioUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Audio URL', hintStyle: TextStyle(color: Colors.grey)),
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
              if (widget.song == null) {
                await widget.db.addSong(
                  name: nameController.text,
                  artistId: artistIdController.text,
                  albumId: albumIdController.text,
                  audioUrl: audioUrlController.text,
                );
              } else {
                await widget.db.updateSong(
                  id: widget.song!.id,
                  name: nameController.text,
                  artistId: artistIdController.text,
                  albumId: albumIdController.text,
                  audioUrl: audioUrlController.text,
                );
              }
              Navigator.pop(context, true); // return true to reload
            }
          },
          child: Text(widget.song == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}
