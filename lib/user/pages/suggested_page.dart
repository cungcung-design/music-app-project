import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/suggested.dart';
import '../../models/artist.dart';
import '../../services/audio_player_service.dart';
import '../widgets/recently_played_section.dart';
import '../widgets/popular_section.dart';
import '../widgets/artist_section.dart';
import '../widgets/artist_detail_page.dart';

class SuggestedPage extends StatefulWidget {
  final DatabaseService db;
  const SuggestedPage({super.key, required this.db});

  @override
  State<SuggestedPage> createState() => _SuggestedPageState();
}

class _SuggestedPageState extends State<SuggestedPage> {
  List<Song> _recentlyPlayed = [];
  List<Song> _popularSongs = [];
  List<Artist> _artists = [];
  bool _isLoading = true;
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final artists = await widget.db.getArtists();
    final recentlyPlayed = await widget.db.getRecentlyPlayedSongs(limit: 5);
    final popularSongs = await widget.db.getPopularSongs(limit: 5);
    setState(() {
      _recentlyPlayed = recentlyPlayed;
      _popularSongs = popularSongs;
      _artists = artists;
      _isLoading = false;
    });
  }

  void _playSong(Song song, List<Song> playlist) async {
    final service = AudioPlayerService();
    service.setPlaylist(playlist);
    service.playSong(song);

    await widget.db.addToPlayHistory(song.id);
    setState(() {
      // Update recently played locally
      _recentlyPlayed.removeWhere((s) => s.id == song.id);
      _recentlyPlayed.insert(0, song);
      if (_recentlyPlayed.length > 5) {
        _recentlyPlayed = _recentlyPlayed.sublist(0, 5);
      }
    });
  }

  void _navigateToArtistDetail(Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistDetailPage(db: widget.db, artist: artist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecentlyPlayedSection(
                  songs: _recentlyPlayed,
                  onSongTap: _playSong,
                ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _audioService,
                  builder: (context, _) => PopularSection(
                    songs: _popularSongs,
                    onSongTap: _playSong,
                    currentSongId: _audioService.currentSong?.id,
                    isPlaying: _audioService.isPlaying,
                  ),
                ),
                const SizedBox(height: 32),
                ArtistSection(
                  artists: _artists,
                  onArtistTap: _navigateToArtistDetail,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
