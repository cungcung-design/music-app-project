import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../utils/toast.dart';

class ManageArtistsPage extends StatefulWidget {
  const ManageArtistsPage({super.key});

  @override
  State<ManageArtistsPage> createState() => _ManageArtistsPageState();
}

class _ManageArtistsPageState extends State<ManageArtistsPage> {
  final DatabaseService db = DatabaseService();
  List<Artist> artists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadArtists();
  }

  Future<void> loadArtists() async {
    setState(() => loading = true);
    final data = await db.getArtists();
    if (mounted) {
      setState(() {
        artists = data;
        loading = false;
      });
    }
  }

  void showArtistForm({Artist? artist}) {
    final nameController = TextEditingController(text: artist?.name ?? '');
    final bioController = TextEditingController(text: artist?.bio ?? '');
    File? selectedImage;
    String? imageFileName = artist?.profileUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            artist == null ? "Add Artist" : "Edit Artist",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Artist Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Artist Bio',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null && result.files.single.path != null) {
                      selectedImage = File(result.files.single.path!);
                      setState(() {
                        imageFileName = result.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Profile Image"),
                ),
                if (imageFileName != null)
                  Text(
                    "Selected: ${imageFileName?.split('/').last}",
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final bio = bioController.text.trim();
                if (name.isEmpty || bio.isEmpty || (artist == null && selectedImage == null)) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }

                try {
                  String? profilePath = artist?.profileUrl;

                  if (selectedImage != null) {
                    profilePath = await db.uploadArtistProfile(selectedImage!);
                  }

                  if (artist == null) {
                    await db.addArtist(
                      name: name,
                      bio: bio,
                      profileUrl: profilePath!,
                    );
                    showToast(context, "Artist added ✅");
                  } else {
                    await db.updateArtist(
                      id: artist.id,
                      name: name,
                      bio: bio,
                      profileUrl: profilePath!,
                    );
                    showToast(context, "Artist updated ✅");
                  }

                  Navigator.pop(context);
                  loadArtists();
                } catch (e) {
                  showToast(context, "Operation failed: $e", isError: true);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteArtist(String id) async {
    await db.deleteArtist(id);
    showToast(context, "Artist deleted ✅");
    loadArtists();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showArtistForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final artist = artists[index];

          return ListTile(
            tileColor: Colors.grey[850],
            leading: artist.profileUrl != null
                ? Image.network(
                    artist.profileUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.person, color: Colors.green),
            title: Text(artist.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(artist.bio, style: const TextStyle(color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showArtistForm(artist: artist),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteArtist(artist.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
