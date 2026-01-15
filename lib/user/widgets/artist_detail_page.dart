import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

class ArtistDetailPage extends StatefulWidget {
  final DatabaseService db;
  final Artist artist;

  const ArtistDetailPage({
    super.key,
    required this.db,
    required this.artist,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late Future<List<Song>> songsFuture;

  @override
  void initState() {
    super.initState();
    songsFuture = widget.db.getSongsByArtist(widget.artist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Image.network(
                      widget.artist.artistProfileUrl ?? '',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),

                  // Gradient
                  Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),

                  // Back button
            Positioned(
  top: 40,
  left: 12,
  child: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
    onPressed: () => Navigator.pop(context),
  ),
),

                  // Artist name
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      widget.artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Popular Songs Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Popular Songs",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Songs List
              Expanded(
                child: FutureBuilder<List<Song>>(
                  future: songsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      );
                    }

                    final songs = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];

                        return ListTile(
                          onTap: () =>
                              AudioPlayerService().playSong(song),

                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.albumImage ?? '',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                child: const Icon(Icons.music_note,
                                    color: Colors.white),
                              ),
                            ),
                          ),

                          title: Text(
                            song.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Text(
                            widget.artist.name,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          trailing: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // 🎵 Mini Player
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
