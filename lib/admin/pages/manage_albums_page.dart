import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    final tableAlbums = await db.getAlbums();
    final storageAlbums = await db.fetchAlbumsFromStorage();

    final tableIds = tableAlbums.map((e) => e.id).toSet();
    final virtualAlbums = storageAlbums.where((a) => !tableIds.contains(a.id)).toList();

    if (mounted) {
      setState(() {
        albums = [...tableAlbums, ...virtualAlbums];
        loading = false;
      });
    }
  }

  Future<void> loadArtists() async {
    final data = await db.getArtists();
    if (mounted) setState(() => artists = data);
  }

  void showAlbumForm({Album? album}) {
    if (album != null && album.artistId.isEmpty) {
      showToast(context, "Cannot edit storage-only album. Use Import instead.", isError: true);
      return;
    }

    final nameController = TextEditingController(text: album?.name ?? '');
    Artist? selectedArtist = album != null
        ? artists.firstWhere((a) => a.id == album.artistId, orElse: () => artists.first)
        : (artists.isNotEmpty ? artists.first : null);

    File? selectedCover;
    Uint8List? selectedCoverBytes;
    String? coverFileName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(album == null ? "Add Album" : "Edit Album",
              style: const TextStyle(color: Colors.white)),
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
                  items: artists
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.name, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedArtist = v),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Cover"),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: kIsWeb, // important for web
                    );
                    if (result != null) {
                      coverFileName = result.files.single.name;
                      if (kIsWeb) {
                        selectedCoverBytes = result.files.single.bytes;
                      } else {
                        selectedCover = File(result.files.single.path!);
                      }
                      setState(() {});
                    }
                  },
                ),
                if (coverFileName != null)
                  Text("Selected: $coverFileName", style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.red))),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selectedArtist == null) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }

                try {
                  if (album == null) {
                    await db.addAlbum(
                      name: name,
                      artistId: selectedArtist!.id,
                      coverFile: selectedCover,
                      coverBytes: selectedCoverBytes,
                    );
                    showToast(context, "Album added ✅");
                  } else {
                    await db.updateAlbum(
                      albumId: album.id,
                      name: name,
                      artistId: selectedArtist!.id,
                      newCoverFile: selectedCover,
                      newCoverBytes: selectedCoverBytes,
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

  void importStorageAlbum(Album album) {
    final nameController = TextEditingController(text: album.name);
    Artist? selectedArtist = artists.isNotEmpty ? artists.first : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Import Album", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "Album Name", hintStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              DropdownButton<Artist>(
                value: selectedArtist,
                dropdownColor: Colors.grey[900],
                isExpanded: true,
                items: artists
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.name, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedArtist = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.red))),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selectedArtist == null) {
                  showToast(context, "All fields required", isError: true);
                  return;
                }
                try {
                  // Insert storage album into DB
                  await db.addAlbum(
                    name: name,
                    artistId: selectedArtist!.id,
                    coverFile: null,
                    coverBytes: null,
                  );
                  showToast(context, "Album imported ✅");
                  Navigator.pop(context);
                  loadAlbums();
                } catch (e) {
                  showToast(context, "Import failed: $e", isError: true);
                }
              },
              child: const Text("Import", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteAlbum(String id, {bool isVirtual = false}) async {
    if (isVirtual) {
      showToast(context, "Cannot delete storage-only album", isError: true);
      return;
    }
    await db.deleteAlbum(id);
    showToast(context, "Album deleted ✅");
    loadAlbums();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Albums'),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: loadAlbums)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showAlbumForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final album = albums[i];
          final artistName = album.artistId.isEmpty
              ? 'Storage only'
              : artists.firstWhere((a) => a.id == album.artistId, orElse: () => Artist(id: '', name: 'Unknown', bio: '')).name;

          return ListTile(
            tileColor: Colors.grey[850],
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                album.albumProfileUrl ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.album, color: Colors.green),
              ),
            ),
            title: Text(album.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text("Artist: $artistName", style: const TextStyle(color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (album.artistId.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.orange),
                    onPressed: () => importStorageAlbum(album),
                    tooltip: "Import",
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showAlbumForm(album: album),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteAlbum(album.id),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
