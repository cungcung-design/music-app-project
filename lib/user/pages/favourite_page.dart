import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';
import '../widgets/mini_player.dart';
import '../../utils/toast.dart';

class FavoritesPage extends StatefulWidget {
  final DatabaseService db;
  const FavoritesPage({super.key, required this.db});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Song>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = widget.db.getFavorites();
  }

  void _playSong(Song song) {
    AudioPlayerService().playSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );
  }

  Future<void> _removeFavorite(Song song) async {
    try {
      await widget.db.removeFromFavorites(song.id);
      setState(() {
        _loadFavorites();
      });
      showToast(context, 'Removed from favorites');
    } catch (e) {
      showToast(context, 'Error removing favorite', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Song>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "No Favorites Yet",
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    Text(
                      "Songs you like will appear here",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final favorites = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Favorites',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _songList(favorites),
                  const SizedBox(height: 110),
                ],
              ),
            );
          },
        ),
        const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      ],
    );
  }

  Widget _songList(List<Song> songs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: song.albumImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(song.albumImage!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(song.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            song.artistName ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => _removeFavorite(song),
          ),
          onTap: () => _playSong(song),
        );
      },
    );
  }
}
