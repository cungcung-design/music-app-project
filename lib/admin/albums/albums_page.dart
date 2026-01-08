import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'add_edit_album.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final DatabaseService db = DatabaseService();
  List<Map<String, dynamic>> albums = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    setState(() => loading = true);
    try {
      final data = await db.getAlbums();
      setState(() => albums = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching albums: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  void deleteAlbum(String id) async {
    try {
      await db.deleteAlbum(id);
      fetchAlbums();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Album deleted ✅')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return ListTile(
                  leading: album['cover_url'] != null
                      ? Image.network(album['cover_url'], width: 50, height: 50)
                      : Container(width: 50, height: 50, color: Colors.grey[800]),
                  title: Text(album['name'] ?? '',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Artist: ${album['artist_id']}',
                      style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddEditAlbumPage(album: album)),
                          ).then((_) => fetchAlbums());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteAlbum(album['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAlbumPage()),
          ).then((_) => fetchAlbums());
        },
      ),
    );
  }
}
