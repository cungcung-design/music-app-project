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
  late Future<SuggestedData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<SuggestedData> _fetchData() async {
    final artists = await widget.db.getArtists();
    final recentlyPlayed = await widget.db.getRecentlyPlayedSongs(limit: 5);
    final popularSongs = await widget.db.getPopularSongs(limit: 5);

    return SuggestedData(
      recentlyPlayed: recentlyPlayed,
      popularSongs: popularSongs,
      artists: artists,
    );
  }

  void _playSong(Song song, List<Song> playlist) async {
    final service = AudioPlayerService();
    service.setPlaylist(playlist);
    service.playSong(song);

    await widget.db.addToPlayHistory(song.id);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<SuggestedData>(
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
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dataFuture = _fetchData();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecentlyPlayedSection(
                      songs: data.recentlyPlayed,
                      onSongTap: _playSong,
                    ),
                    const SizedBox(height: 32),
                    PopularSection(
                      songs: data.popularSongs,
                      onSongTap: _playSong,
                    ),
                    const SizedBox(height: 32),
                    ArtistSection(
                      artists: data.artists,
                      onArtistTap: _navigateToArtistDetail,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
