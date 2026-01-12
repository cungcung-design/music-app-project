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
    loadAlbums();
    loadArtists();
  }

  Future<void> loadAlbums() async {
    setState(() => loading = true);
    final data = await db.getAlbums();
    if (mounted) {
      setState(() {
        albums = data;
        loading = false;
      });
    }
  }

  Future<void> loadArtists() async {
    final data = await db.getArtists();
    if (mounted) {
      setState(() {
        artists = data;
      });
    }
  }

  void showAlbumForm({Album? album}) {
    final nameController = TextEditingController(text: album?.name ?? '');
    Artist? selectedArtist = album != null
        ? artists.firstWhere(
            (a) => a.id == album.artistId,
            orElse: () => artists.first,
          )
        : (artists.isNotEmpty ? artists.first : null);

    File? selectedCover;
    String? coverFileName;

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
                    hintText: "Album Name",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<Artist>(
                  value: selectedArtist,
                  dropdownColor: Colors.grey[900],
                  isExpanded: true,
                  items: artists.map((artist) {
                    return DropdownMenuItem(
                      value: artist,
                      child: Text(
                        artist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedArtist = val),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.image);
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
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty ||
                    selectedArtist == null ||
                    (album == null && selectedCover == null)) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }

                try {
                  if (album == null) {
                    await db.addAlbum(
                      name: name,
                      artistId: selectedArtist!.id,
                      coverFile: selectedCover,
                    );
                    showToast(context, "Album added ✅");
                  } else {
                    await db.updateAlbum(
                      albumId: album.id,
                      name: name,
                      artistId: selectedArtist!.id,
                      newCoverFile: selectedCover,
                    );
                    showToast(context, "Album updated ✅");
                  }

                  Navigator.pop(context);
                  loadAlbums();
                } catch (e) {
                  showToast(context, "Operation failed: $e", isError: true);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteAlbum(String id) async {
    await db.deleteAlbum(id);
    showToast(context, "Album deleted ✅");
    loadAlbums();
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Albums'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadAlbums(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showAlbumForm(),
        child: const Icon(Icons.add), // ✅ Add Album icon
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final album = albums[index];
          final artistName = artists
              .firstWhere(
                (a) => a.id == album.artistId,
                orElse: () => Artist(id: '', name: 'Unknown', bio: ''),
              )
              .name;

          return ListTile(
            tileColor: Colors.grey[850],
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[700],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  album.albumProfileUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.album, color: Colors.green),
                ),
              ),
            ),
            title: Text(
              album.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Artist: $artistName",
              style: const TextStyle(color: Colors.grey),
            ),
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
