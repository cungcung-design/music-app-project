import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class SongsPage extends StatelessWidget {
  final DatabaseService db;
  const SongsPage({super.key, required this.db});

  Future<List<Song>> fetchSongs() async {
    return await db.getSongsWithDetails();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Song>>(
      future: fetchSongs(),
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
              'No songs available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final songs = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final song = songs[index];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[700],
                ),
                child: song.albumImage != null && song.albumImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song.albumImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.music_note, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.music_note, color: Colors.white),
              ),
              title: Text(
                song.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: song.artistName != null
                  ? Text(
                      song.artistName!,
                      style: const TextStyle(color: Colors.grey),
                    )
                  : null,
              onTap: () {
                if (song.audioUrl?.isEmpty ?? true) return;
                AudioPlayerService().playSong(song);
              },
            );
          },
        );
      },
    );
  }
}
