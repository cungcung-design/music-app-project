import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../utils/toast.dart';

class ManageAlbumsPage extends StatefulWidget {
  const ManageAlbumsPage({super.key});

  @override
  State<ManageAlbumsPage> createState() => _ManageAlbumsPageState();
}

class _ManageAlbumsPageState extends State<ManageAlbumsPage> {
  final DatabaseService db = DatabaseService();
  List<Album> albums = [];
  List<Artist> artists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final albumsData = await db.getAlbums();
    final artistsData = await db.getArtists();
    if (mounted) {
      setState(() {
        albums = albumsData;
        artists = artistsData;
        loading = false;
      });
    }
  }

  void showAlbumForm({Album? album}) {
    final nameController = TextEditingController(text: album?.name ?? '');
    String? selectedArtistId = album?.artistId;
    File? selectedCover;
    String? coverFileName = album?.coverUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            album == null ? "Add Album" : "Edit Album",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Album Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedArtistId,
                  items: artists.map((artist) {
                    return DropdownMenuItem(
                      value: artist.id,
                      child: Text(artist.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedArtistId = value),
                  decoration: const InputDecoration(
                    labelText: 'Select Artist',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null && result.files.single.path != null) {
                      selectedCover = File(result.files.single.path!);
                      setState(() {
                        coverFileName = result.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Album Cover"),
                ),
                if (coverFileName != null)
                  Text(
                    "Selected: ${coverFileName?.split('/').last}",
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
                if (name.isEmpty || selectedArtistId == null || (album == null && selectedCover == null)) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }

                try {
                  String? coverPath = album?.coverUrl;

                  if (selectedCover != null) {
                    coverPath = await db.uploadAlbumCover(selectedCover!);
                  }

                  if (album == null) {
                    await db.addAlbum(
                      name: name,
                      artistId: selectedArtistId!,
                      coverUrl: coverPath!,
                    );
                    showToast(context, "Album added ✅");
                  } else {
                    await db.updateAlbum(
                      id: album.id,
                      name: name,
                      artistId: selectedArtistId!,
                      coverUrl: coverPath!,
                    );
                    showToast(context, "Album updated ✅");
                  }

                  Navigator.pop(context);
                  loadAll();
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

  Future<void> deleteAlbum(String id) async {
    await db.deleteAlbum(id);
    showToast(context, "Album deleted ✅");
    loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showAlbumForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final album = albums[index];
          final artist = artists.firstWhere((a) => a.id == album.artistId, orElse: () => Artist(id: '', name: 'Unknown', bio: ''));

          return ListTile(
            tileColor: Colors.grey[850],
            leading: album.coverUrl != null
                ? Image.network(
                    album.coverUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.album, color: Colors.green),
            title: Text(album.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text("Artist: ${artist.name}", style: const TextStyle(color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showAlbumForm(album: album),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteAlbum(album.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
