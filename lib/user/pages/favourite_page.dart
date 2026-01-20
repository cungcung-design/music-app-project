import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/playing_song_page.dart';

class FavoritesPage extends StatefulWidget {
  final DatabaseService db;
  const FavoritesPage({super.key, required this.db});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Song>? _localSongs;
  bool _isLoading = true;
  StreamSubscription<void>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Listen for favorites changes if your DatabaseService emits events
    _favoritesSubscription = widget.db.favoritesChanged.listen((_) {
      _refreshData();
    });
  }

  /// Initial load
  Future<void> _fetchInitialData() async {
    try {
      final songs = await widget.db.getFavorites();
      if (mounted) {
        setState(() {
          _localSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Refresh data (reload from DB)
  Future<void> _refreshData() async {
    final songs = await widget.db.getFavorites();
    if (mounted) setState(() => _localSongs = songs);
  }

  /// Pull-to-refresh
  Future<void> _onPullRefresh() async => _refreshData();

  /// Play a song
  Future<void> _playSong(Song song, List<Song> playlist) async {
    final service = AudioPlayerService();
    service.setPlaylist(playlist);
    service.playSong(song);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );

    _refreshData();
  }

  /// Remove from favorites
  Future<void> _removeFromFavorites(String songId) async {
    final originalList = List<Song>.from(_localSongs ?? []);

    setState(() {
      _localSongs?.removeWhere((s) => s.id == songId);
    });

    try {
      await widget.db.removeFromFavorites(songId);
    } catch (e) {
      setState(() => _localSongs = originalList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _onPullRefresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : (_localSongs == null || _localSongs!.isEmpty)
              ? _buildEmptyState()
              : _buildSongList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Favorites yet',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: Colors.green,
      backgroundColor: Colors.black,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _localSongs!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, i) {
          final song = _localSongs![i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.albumImage != null
                  ? Image.network(
                      song.albumImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            title: Text(
              song.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              song.artistName ?? 'Unknown Artist',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFromFavorites(song.id),
            ),
            onTap: () => _playSong(song, _localSongs!),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.green),
    );
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
