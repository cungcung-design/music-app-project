import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class AlbumsPage extends StatelessWidget {
  final DatabaseService db;
  const AlbumsPage({super.key, required this.db});

  Future<List<Album>> fetchAlbums() async {
    return await db.getAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: fetchAlbums(),
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

        return ListView.separated(
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
                // Optional: fetch songs of album
                final songs = await db.getSongsByAlbum(album.id);
                if (songs.isNotEmpty) {
                  AudioPlayerService().playSong(songs.first);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing: ${songs.first.name}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
