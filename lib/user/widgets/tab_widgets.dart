import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../models/suggested.dart';
import '../../services/audio_player_service.dart';
import 'mini_player.dart';
import 'playing_song_page.dart';
import 'artist_detail_page.dart';

class SuggestedTab extends StatefulWidget {
  final DatabaseService db;
  const SuggestedTab({super.key, required this.db});

  @override
  State<SuggestedTab> createState() => _SuggestedTabState();
}

class _SuggestedTabState extends State<SuggestedTab> {
  late Future<SuggestedData> _dataFuture;
  final String? userId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchData();
  }

  Future<SuggestedData> fetchData() async {
    final artists = await widget.db.getArtists();
    List<Song> recommendedSongs = [];

    if (userId != null) {
      recommendedSongs = await widget.db.getRecommendedSongs(
        userId!,
        limit: 10,
      );
    }

    final allSongs = await widget.db.getSongsWithDetails();
    allSongs.sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
    final recentlyPlayed = allSongs.take(5).toList();

    return SuggestedData(
      recentlyPlayed: recentlyPlayed,
      recommended: recommendedSongs,
      artists: artists,
    );
  }

  void _playSong(Song song) {
    AudioPlayerService().playSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SuggestedData>(
      future: _dataFuture,
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

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Recently Played'),
              const SizedBox(height: 12),
              _songList(data.recentlyPlayed),
              const SizedBox(height: 24),
              _sectionTitle('Recommended For You'),
              const SizedBox(height: 12),
              _songList(data.recommended),
              const SizedBox(height: 24),
              _sectionTitle('Artists'),
              const SizedBox(height: 12),
              _artistList(data.artists),
              const SizedBox(height: 110), // Space for MiniPlayer
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _songList(List<Song> songs) {
    if (songs.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No songs available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () => _playSong(song),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[800],
                    ),
                    child:
                        song.albumImage != null && song.albumImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.albumImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (song.artistName != null)
                    Text(
                      song.artistName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _artistList(List<Artist> artists) {
    if (artists.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No artists available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ArtistDetailPage(db: widget.db, artist: artist),
                ),
              );
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[700],
                  child:
                      artist.artistProfileUrl != null &&
                          artist.artistProfileUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            artist.artistProfileUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SongsTab extends StatelessWidget {
  final DatabaseService db;
  const SongsTab({super.key, required this.db});

  void _playSong(BuildContext context, Song song) {
    AudioPlayerService().playSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Song>>(
      future: db.getSongsWithDetails(),
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
                color: Colors.grey[700],
                child: song.albumImage != null && song.albumImage!.isNotEmpty
                    ? Image.network(song.albumImage!, fit: BoxFit.cover)
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
              onTap: () => _playSong(context, song),
            );
          },
        );
      },
    );
  }
}

class ArtistsTab extends StatelessWidget {
  final DatabaseService db;
  const ArtistsTab({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: db.getArtists(),
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
              'No artists available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final artists = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: artists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[700],
                child:
                    artist.artistProfileUrl != null &&
                        artist.artistProfileUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          artist.artistProfileUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                artist.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                artist.bio ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailPage(db: db, artist: artist),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class AlbumsTab extends StatelessWidget {
  final DatabaseService db;
  const AlbumsTab({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: db.getAlbums(),
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
                child:
                    album.albumProfileUrl != null &&
                        album.albumProfileUrl!.isNotEmpty
                    ? Image.network(album.albumProfileUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.album, color: Colors.white),
              ),
              title: Text(
                album.name,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
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
