import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class AlbumsPage extends StatefulWidget {
  final DatabaseService db;
  const AlbumsPage({super.key, required this.db});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = widget.db.getAlbums();
  }

  Future<void> _refreshAlbums() async {
    setState(() {
      _albumsFuture = widget.db.getAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No albums available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final albums = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshAlbums,
          color: Colors.green,
          backgroundColor: Colors.black,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final album = albums[index];
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[700],
                  child: Image.network(
                    album.albumProfileUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.album, color: Colors.white),
                  ),
                ),
                title: Text(
                  album.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final songs = await widget.db.getSongsByAlbum(album.id);
                  if (songs.isNotEmpty) {
                    AudioPlayerService().playSong(songs.first);
                    await widget.db.addToPlayHistory(songs.first.id);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
