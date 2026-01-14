import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../utils/toast.dart';
import 'album_detail_page.dart';

class ManageAlbumsPage extends StatefulWidget {
  const ManageAlbumsPage({super.key});

  @override
  State<ManageAlbumsPage> createState() => _ManageAlbumsPageState();
}

class _ManageAlbumsPageState extends State<ManageAlbumsPage> {
  final DatabaseService db = DatabaseService();
  List<Album> albums = [];
  List<Artist> artists = [];
  List<Song> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      albums = await db.getAlbums();
      artists = await db.getArtists();
      songs = await db.getSongsWithDetails();
    } catch (e) {
      showToast(context, "Failed to load data: $e", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showAlbumForm({Album? album}) async {
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
          title: Text(album == null ? "Add Album" : "Edit Album", style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Album Name", 
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<Artist>(
                  value: selectedArtist,
                  dropdownColor: Colors.grey[900],
                  isExpanded: true,
                  items: artists.map((a) => DropdownMenuItem(
                    value: a, 
                    child: Text(a.name, style: const TextStyle(color: Colors.white))
                  )).toList(),
                  onChanged: (v) => setState(() => selectedArtist = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  icon: const Icon(Icons.image, color: Colors.green),
                  label: const Text("Pick Cover Art", style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(coverFileName!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selectedArtist == null) return;
                if (album == null) {
                  await db.addAlbum(name: name, artistId: selectedArtist!.id, coverFile: selectedCover, coverBytes: selectedCoverBytes);
                } else {
                  await db.updateAlbum(albumId: album.id, name: name, artistId: selectedArtist!.id, newCoverFile: selectedCover, newCoverBytes: selectedCoverBytes);
                }
                Navigator.pop(context);
                loadData();
              },
              child: const Text("Save", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return Scaffold(
      backgroundColor: Colors.black,
      
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final album = albums[i];
          final artist = artists.firstWhere((a) => a.id == album.artistId, orElse: () => Artist(id: '', name: 'Unknown', bio: ''));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: 'album-${album.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    album.albumProfileUrl ?? '',
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.album, color: Colors.green, size: 50),
                  ),
                ),
              ),
              title: Text(album.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(artist.name, style: const TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlbumDetailPage(album: album, songs: songs, artists: artists)),
              ).then((_) => loadData()), // Refresh data when returning
            ),
          );
        },
      ),
    );
  }
}