import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class SongsPage extends StatefulWidget {
  final DatabaseService db;
  const SongsPage({super.key, required this.db});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = widget.db.getSongsWithDetails();
  }

  Future<void> _refreshSongs() async {
    setState(() {
      _songsFuture = widget.db.getSongsWithDetails();
    });
  }

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
            future: _songsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.green));
              }

              final songs = snapshot.data!;

              return RefreshIndicator(
                onRefresh: _refreshSongs,
                color: Colors.green,
                backgroundColor: Colors.black,
                child: ListenableBuilder(
                  listenable: playerService,
                  builder: (context, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: 10),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        final bool isPlaying =
                            playerService.currentSong?.id == song.id;

                        return ListTile(
                          onTap: () async {
                            playerService.setPlaylist(songs);
                            playerService.playSong(song);
                            await widget.db.addToPlayHistory(song.id);
                          },
                          leading: SizedBox(
                            width: 30,
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isPlaying
                                      ? Colors.green
                                      : Colors.grey, // Number turns green
                                  fontWeight: isPlaying
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.name,
                            style: TextStyle(
                                color: isPlaying ? Colors.green : Colors.white),
                          ),
                          subtitle: Text(song.artistName ?? "Unknown Artist",
                              style: const TextStyle(color: Colors.grey)),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
