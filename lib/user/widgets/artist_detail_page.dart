import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

class ArtistDetailPage extends StatefulWidget {
  final DatabaseService db;
  final Artist artist;

  const ArtistDetailPage({super.key, required this.db, required this.artist});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = widget.db.getSongsByArtist(widget.artist.id);
  }

  void _playSong(Song song) {
    if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      AudioPlayerService().playSong(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(widget.artist.name),
      ),

      body: Stack(
        children: [
          // MAIN CONTENT
          Padding(
            padding: const EdgeInsets.only(bottom: 90), // space for MiniPlayer
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ARTIST HEADER
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[700],
                        child: widget.artist.artistProfileUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.artist.artistProfileUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 50,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.artist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.artist.about != null)
                              Text(
                                widget.artist.about!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // SONG LIST
                  FutureBuilder<List<Song>>(
                    future: _songsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final songs = snapshot.data ?? [];
                      if (songs.isEmpty) {
                        return const Text(
                          'No songs available',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Songs (${songs.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: songs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.grey),
                            itemBuilder: (_, index) {
                              final song = songs[index];

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: song.albumImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            song.albumImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                        ),
                                ),
                                title: Text(
                                  song.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: song.artistName != null
                                    ? Text(
                                        song.artistName!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.greenAccent,
                                  ),
                                  onPressed: () => _playSong(song),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ✅ GLOBAL MINIPLAYER
          const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ],
      ),
    );
  }
}
