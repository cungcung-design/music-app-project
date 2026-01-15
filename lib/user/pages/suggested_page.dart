import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/suggested.dart';
import '../../models/artist.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';
import '../widgets/popular_section.dart';
import '../widgets/recently_played_section.dart';
import '../widgets/artist_section.dart';
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
    _dataFuture = _fetchData();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await widget.db.getFavorites();
    setState(() {
      _favoriteSongIds = favorites.map((s) => s.id).toSet();
    });
  }

  Future<SuggestedData> _fetchData() async {
    final artists = await widget.db.getArtists();
    final allSongs = await widget.db.getSongsWithDetails();

    allSongs.sort(
      (a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0),
    );

    final popularSongs = await widget.db.getPopularSongs(limit: 5);

    return SuggestedData(
      recentlyPlayed: allSongs.take(5).toList(),
      popularSongs: popularSongs,
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

  Future<void> _toggleFavorite(Song song) async {
    final isFavorite = _favoriteSongIds.contains(song.id);

    if (isFavorite) {
      await widget.db.removeFromFavorites(song.id);
      _favoriteSongIds.remove(song.id);
      showToast(context, 'Removed from favorites');
    } else {
      await widget.db.addToFavorites(song.id);
      _favoriteSongIds.add(song.id);
      showToast(context, 'Added to favorites');
    }

    setState(() {});
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

        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecentlyPlayedSection(
                songs: data.recentlyPlayed,
                onSongTap: _playSong,
              ),

              const SizedBox(height: 24),
              PopularSection(
                songs: data.popularSongs,
                onSongTap: _playSong,
              ),

              const SizedBox(height: 24),
              ArtistSection(artists: data.artists),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
