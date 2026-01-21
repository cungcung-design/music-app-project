import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/audio_player_service.dart';
import 'mini_player.dart';

class AlbumDetailPage extends StatefulWidget {
  final DatabaseService db;
  final Album album;

  const AlbumDetailPage({super.key, required this.db, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late Future<String?> _artistNameFuture;

  @override
  void initState() {
    super.initState();
    _artistNameFuture = _fetchArtistName();
  }

  Future<String?> _fetchArtistName() async {
    final artist = await widget.db.getArtistById(widget.album.artistId);
    if (artist != null) {
      return artist.name;
    }
    // If artist not found in artists table, fetch from songs
    final songs = await widget.db.getSongsByAlbum(widget.album.id);
    if (songs.isNotEmpty) {
      return songs.first.artistName;
    }
    return 'Unknown Artist';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: AudioPlayerService(),
            builder: (context, _) {
              final currentSong = AudioPlayerService().currentSong;

              return FutureBuilder<List<Song>>(
                future: widget.db.getSongsByAlbum(widget.album.id),
                builder: (context, snapshot) {
                  final songs = snapshot.data ?? [];

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // --- MODERN SLEEK APPBAR ---
                      SliverAppBar(
                        expandedHeight: 340,
                        pinned: true,
                        elevation: 0,
                        stretch: true,
                        backgroundColor: const Color(0xFF0A0A0A),
                        leading: _buildBackButton(context),
                        flexibleSpace: FlexibleSpaceBar(
                          stretchModes: const [StretchMode.zoomBackground],
                          background: _buildHeaderBackground(widget.album),
                        ),
                      ),

                      // --- PLAY BUTTON SECTION ---
                      SliverToBoxAdapter(
                        child: _buildPlayActionRow(songs, widget.db),
                      ),

                      // --- SONG LIST ---
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = songs[index];
                              final isPlaying = song.id == currentSong?.id;

                              return _SongListTile(
                                index: index,
                                song: song,
                                isPlaying: isPlaying,
                                onTap: () async {
                                  AudioPlayerService().playSong(song);
                                  await widget.db.addToPlayHistory(song.id);
                                },
                              );
                            },
                            childCount: songs.length,
                          ),
                        ),
                      ),

                      // Bottom Padding for MiniPlayer
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  );
                },
              );
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.4),
        child: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(Album album) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'album-${album.id}',
          child: Image.network(album.albumProfileUrl ?? '', fit: BoxFit.cover),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                const Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 30,
          right: 20,
          child: FutureBuilder<String?>(
            future: _artistNameFuture,
            builder: (context, snapshot) {
              final artistName = snapshot.data ?? 'Unknown Artist';
              return Text(
                album.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayActionRow(List<Song> songs, DatabaseService db) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _PlayButton(onTap: () {
            if (songs.isNotEmpty) {
              AudioPlayerService().playSong(songs.first);
              db.addToPlayHistory(songs.first.id);
            }
          }),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Album',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text('${songs.length} Tracks',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS FOR CLARITY ---

class _SongListTile extends StatelessWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongListTile({
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 30,
        alignment: Alignment.centerLeft,
        child: isPlaying
            ? const Icon(Icons.bar_chart,
                color: Colors.green) // Modern "Playing" indicator
            : Text(
                '${index + 1}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
      ),
      title: Text(
        song.name,
        style: TextStyle(
          color: isPlaying ? Colors.green : Colors.white,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        song.artistName ?? 'Unknown Artist',
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      ),
      trailing: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.2)),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration:
            const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow, color: Colors.black, size: 30),
      ),
    );
  }
}
