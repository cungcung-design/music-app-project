import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/suggested.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';
import '../widgets/mini_player.dart'; // Make sure this is imported
import '../../utils/toast.dart';

class SuggestedPage extends StatefulWidget {
  final DatabaseService db;
  const SuggestedPage({super.key, required this.db});

  @override
  State<SuggestedPage> createState() => _SuggestedPageState();
}

class _SuggestedPageState extends State<SuggestedPage> {
  late Future<SuggestedData> _dataFuture;
  Set<String> _favoriteSongIds = {};

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchData();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await widget.db.getFavorites();
      setState(() {
        _favoriteSongIds = favorites.map((song) => song.id).toSet();
      });
    } catch (e) {
      // Handle error silently or show toast
    }
  }

  Future<SuggestedData> fetchData() async {
    final artists = await widget.db.getArtists();
    final allSongs = await widget.db.getSongsWithDetails();
    final recentlyPlayed = allSongs
      ..sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));

    return SuggestedData(
      recentlyPlayed: recentlyPlayed.take(5).toList(),
      recommended: [], // Add your logic for recommended
      artists: artists,
    );
  }

  void _playSong(Song song) {
    AudioPlayerService().playSong(song);
    // Optional: Auto-open the full screen page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );
  }

  Future<void> _toggleFavorite(Song song) async {
    final isFavorite = _favoriteSongIds.contains(song.id);
    try {
      if (isFavorite) {
        await widget.db.removeFromFavorites(song.id);
        setState(() {
          _favoriteSongIds.remove(song.id);
        });
        showToast(context, 'Removed from favorites');
      } else {
        await widget.db.addToFavorites(song.id);
        setState(() {
          _favoriteSongIds.add(song.id);
        });
        showToast(context, 'Added to favorites');
      }
    } catch (e) {
      showToast(context, 'Error updating favorite', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<SuggestedData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }
            if (!snapshot.hasData) return const SizedBox();

            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Recently Played'),
                  const SizedBox(height: 12),
                  _songList(data.recentlyPlayed),
                  const SizedBox(
                    height: 110,
                  ), // Space so bottom list items aren't hidden
                ],
              ),
            );
          },
        ),

        // The dedicated MiniPlayer widget
        const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      ],
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
    return SizedBox(
      height: 200, // Increased height to accommodate favorite icon
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isFavorite = _favoriteSongIds.contains(song.id);
          return GestureDetector(
            onTap: () => _playSong(song),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: song.albumImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  song.albumImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.music_note, color: Colors.white),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _toggleFavorite(song),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(song.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
