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
    _favoritesSubscription = widget.db.favoritesChanged.listen((_) {
      _refreshData();
    });
  }

  /// Initial load from Database
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

  /// Refresh logic (used when returning from NowPlayingPage)
  Future<void> _refreshData() async {
    final songs = await widget.db.getFavorites();
    if (mounted && !_areListsEqual(_localSongs, songs)) {
      setState(() => _localSongs = songs);
    }
  }

  /// Pull-to-refresh logic
  Future<void> _onPullRefresh() async {
    final songs = await widget.db.getFavorites();
    if (mounted) {
      setState(() => _localSongs = songs);
    }
  }

  bool _areListsEqual(List<Song>? list1, List<Song>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Plays song and refreshes on return to catch changes made in NowPlayingPage
  Future<void> _playSong(Song song, List<Song> playlist) async {
    final service = AudioPlayerService();
    service.setPlaylist(playlist);
    service.playSong(song);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NowPlayingPage(song: song)),
    );

    // Refresh immediately upon returning in case the user unfavorited the song there
    _refreshData();
  }

  /// INSTANT REMOVAL (Optimistic UI)
  Future<void> _removeFromFavorites(String songId) async {
    // 1. Store a backup in case the database call fails
    final originalList = List<Song>.from(_localSongs ?? []);

    // 2. Update UI instantly
    setState(() {
      _localSongs?.removeWhere((s) => s.id == songId);
    });

    try {
      // 3. Attempt database removal
      await widget.db.removeFromFavorites(songId);
    } catch (e) {
      // 4. If it fails, roll back the UI to the original state
      setState(() => _localSongs = originalList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update favorites. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          Text('No Favorites yet',
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: Colors.green,
      backgroundColor: Colors.black,
      child: ListView.builder(
        itemCount: _localSongs!.length,
        itemBuilder: (_, i) {
          final song = _localSongs![i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
}
