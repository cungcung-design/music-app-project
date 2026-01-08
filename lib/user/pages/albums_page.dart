import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';

class AlbumsPage extends StatefulWidget {
  final DatabaseService db;
  const AlbumsPage({super.key, required this.db});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<Album> albums = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final data = await widget.db.getAlbums();
    setState(() {
      albums = data.map((e) => Album.fromMap(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final album = albums[index];
        return ListTile(
          tileColor: Colors.grey[850],
          leading: album.coverUrl != null && album.coverUrl!.isNotEmpty
              ? Image.network(album.coverUrl!, width: 40, height: 40, fit: BoxFit.cover)
              : const Icon(Icons.album, color: Colors.white),
          title: Text(album.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Artist ID: ${album.artistId}', style: const TextStyle(color: Colors.grey)),
        );
      },
    );
  }
}
