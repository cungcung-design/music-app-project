import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/suggested.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';
import '../widgets/mini_player.dart';
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
      if (mounted) {
        setState(() {
          _favoriteSongIds = favorites.map((song) => song.id).toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<SuggestedData> fetchData() async {
    try {
      final artists = await widget.db.getArtists();
      final allSongs = await widget.db.getSongsWithDetails();
      
      // Sort Recently Played by playCount descending
      final recentlyPlayed = allSongs.toList()
        ..sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));

      return SuggestedData(
        recentlyPlayed: recentlyPlayed.take(10).toList(), // Show up to 10
        recommended: [], // Empty as requested
        artists: artists,
      );
    } catch (e) {
      debugPrint("Error fetching data: $e");
      return SuggestedData(recentlyPlayed: [], recommended: [], artists: []);
    }
  }

  void _playSong(Song song) {
    AudioPlayerService().playSong(song);
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
        setState(() => _favoriteSongIds.remove(song.id));
        showToast(context, 'Removed from favorites');
      } else {
        await widget.db.addToFavorites(song.id);
        setState(() => _favoriteSongIds.add(song.id));
        showToast(context, 'Added to favorites');
      }
    } catch (e) {
      showToast(context, 'Error updating favorite', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<SuggestedData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.recentlyPlayed.isEmpty) {
                return const Center(
                  child: Text("No recently played songs", 
                  style: TextStyle(color: Colors.white70)),
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

                    // No Recommended section here anymore
                    
                    const SizedBox(height: 120), // Padding for MiniPlayer
                  ],
                ),
              );
            },
          ),

          // MiniPlayer at the bottom
          const Align(
            alignment: Alignment.bottomCenter, 
            child: MiniPlayer()
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _songList(List<Song> songs) {
    return SizedBox(
      height: 200, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isFavorite = _favoriteSongIds.contains(song.id);
          
          return GestureDetector(
            onTap: () => _playSong(song),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (song.albumImage != null && song.albumImage!.isNotEmpty)
                              ? Image.network(
                                  song.albumImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, e, s) => const Icon(Icons.music_note, color: Colors.white),
                                )
                              : const Icon(Icons.music_note, color: Colors.white, size: 40),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                          ),
                          onPressed: () => _toggleFavorite(song),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artistName ?? 'Unknown Artist',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}