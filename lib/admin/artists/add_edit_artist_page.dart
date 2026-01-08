import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AddEditArtistPage extends StatefulWidget {
  final Map<String, dynamic>? artist;
  const AddEditArtistPage({Key? key, this.artist}) : super(key: key);

  @override
  State<AddEditArtistPage> createState() => _AddEditArtistPageState();
}

class _AddEditArtistPageState extends State<AddEditArtistPage> {
  final DatabaseService db = DatabaseService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController profileUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!['name'] ?? '';
      bioController.text = widget.artist!['bio'] ?? '';
      profileUrlController.text = widget.artist!['profile_url'] ?? '';
    }
  }

  void saveArtist() async {
    try {
      if (widget.artist == null) {
        await db.addArtist(
          name: nameController.text.trim(),
          bio: bioController.text.trim(),
          profileUrl: profileUrlController.text.trim(),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Artist added ✅')));
      } else {
        await db.updateArtist(
          id: widget.artist!['id'],
          name: nameController.text.trim(),
          bio: bioController.text.trim(),
          profileUrl: profileUrlController.text.trim(),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Artist updated ✅')));
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
        title: Text(widget.artist == null ? 'Add Artist' : 'Edit Artist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Artist Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Bio',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: profileUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: 'Profile Image URL',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveArtist,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(widget.artist == null ? 'Add Artist' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
