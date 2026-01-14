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
    final playerService = AudioPlayerService();

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Song>>(
        future: fetchSongs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No songs available', style: TextStyle(color: Colors.white54)));
          }

          final songs = snapshot.data!;

          return ListenableBuilder(
            listenable: playerService,
            builder: (context, _) {
              return ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 140), // Space for global player
                itemCount: songs.length,
                itemBuilder: (_, index) {
                  final song = songs[index];
                  final bool isPlaying = playerService.currentSong?.id == song.id;

                  return GestureDetector(
                    onTap: () {
                      if (song.audioUrl?.isEmpty ?? true) return;
                      playerService.setPlaylist(songs);
                      playerService.playSong(song);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // Subtle highlight if playing
                        color: isPlaying ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // --- MODERN ALBUM ART ---
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: song.albumImage != null && song.albumImage!.isNotEmpty
                                      ? Image.network(song.albumImage!, fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.grey[850],
                                          child: const Icon(Icons.music_note, color: Colors.white24),
                                        ),
                                ),
                              ),
                              if (isPlaying)
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.pause, color: Colors.green, size: 30),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // --- SONG INFO ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.name,
                                  style: TextStyle(
                                    color: isPlaying ? Colors.green : Colors.white,
                                    fontSize: 16,
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artistName ?? 'Unknown Artist',
                                  style: TextStyle(
                                    color: isPlaying ? Colors.green.withOpacity(0.7) : Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // --- TRAILING ICON ---
                          if (isPlaying)
                             const Icon(Icons.equalizer, color: Colors.green)
                          else
                            const Icon(Icons.more_vert, color: Colors.white24),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          );
        },
      ),
    );
  }
}