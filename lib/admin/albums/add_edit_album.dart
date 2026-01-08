import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AddEditAlbumPage extends StatefulWidget {
  final Map<String, dynamic>? album;
  const AddEditAlbumPage({Key? key, this.album}) : super(key: key);

  @override
  State<AddEditAlbumPage> createState() => _AddEditAlbumPageState();
}

class _AddEditAlbumPageState extends State<AddEditAlbumPage> {
  final DatabaseService db = DatabaseService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController artistController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.album != null) {
      nameController.text = widget.album!['name'] ?? '';
      artistController.text = widget.album!['artist_id'] ?? '';
      coverUrlController.text = widget.album!['cover_url'] ?? '';
    }
  }

  void saveAlbum() async {
    try {
      if (widget.album == null) {
        await db.addAlbum(
          name: nameController.text.trim(),
          artistId: artistController.text.trim(),
          coverUrl: coverUrlController.text.trim(),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Album added ✅')));
      } else {
        await db.updateAlbum(
          id: widget.album!['id'],
          name: nameController.text.trim(),
          artistId: artistController.text.trim(),
          coverUrl: coverUrlController.text.trim(),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Album updated ✅')));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.album == null ? 'Add Album' : 'Edit Album'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Album Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: artistController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Artist ID',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coverUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Cover Image URL',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveAlbum,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(widget.album == null ? 'Add Album' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
