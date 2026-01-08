import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';

class SuggestedPage extends StatefulWidget {
  final DatabaseService db;
  const SuggestedPage({super.key, required this.db});

  @override
  State<SuggestedPage> createState() => _SuggestedPageState();
}

class _SuggestedPageState extends State<SuggestedPage> {
  List<Song> recentlyPlayed = [];
  List<Song> recommended = [];
  List<Artist> artists = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    // Fetch songs & artists
    final songsData = await widget.db.getSongs();
    final artistsData = await widget.db.getArtists();

    setState(() {
      recentlyPlayed = songsData.take(5).map((e) => Song.fromMap(e)).toList();
      recommended = songsData.skip(5).take(5).map((e) => Song.fromMap(e)).toList();
      artists = artistsData.map((e) => Artist.fromMap(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recently Played
          const Text('Recently Played', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyPlayed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final song = recentlyPlayed[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[800],
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Recommended
          const Text('Recommended', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final song = recommended[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[700],
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Artists
          const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final artist = artists[index];
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[700],
                      child: artist.profileUrl != null && artist.profileUrl!.isNotEmpty
                          ? ClipOval(child: Image.network(artist.profileUrl!, width: 80, height: 80, fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
