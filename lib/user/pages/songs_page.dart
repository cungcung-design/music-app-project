import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

class SongsPage extends StatelessWidget {
  final DatabaseService db;
  const SongsPage({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("All Songs", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Song>>(
            future: db.getSongsWithDetails(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              }
              
              final songs = snapshot.data!;

              return ListenableBuilder(
                listenable: playerService,
                builder: (context, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 10),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final bool isPlaying = playerService.currentSong?.id == song.id;

                      return ListTile(
                        onTap: () {
                          playerService.setPlaylist(songs);
                          playerService.playSong(song);
                        },
leading: SizedBox(
  width: 30,
  child: Center(
    child: Text(
      "${index + 1}",
      style: TextStyle(
        
        color: isPlaying ? Colors.green : Colors.grey,
        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
    ),
  ),
),
                        title: Text(
                          song.name,
                          style: TextStyle(
                            color: isPlaying ? Colors.green : Colors.white,
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(song.artistName ?? "Unknown Artist", style: const TextStyle(color: Colors.grey)),
                        trailing: isPlaying 
                          ? const Icon(Icons.equalizer, color: Colors.green)
                          : const Icon(Icons.more_vert, color: Colors.white24),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Global Mini Player
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}