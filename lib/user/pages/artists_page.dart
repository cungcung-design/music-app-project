import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../widgets/artist_detail_page.dart';

class ArtistsPage extends StatefulWidget {
  final DatabaseService db;
  const ArtistsPage({super.key, required this.db});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  late Future<List<Artist>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    _artistsFuture = widget.db.getArtists();
  }

  Future<void> _refreshArtists() async {
    setState(() {
      _artistsFuture = widget.db.getArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: _artistsFuture,
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

        return RefreshIndicator(
          onRefresh: _refreshArtists,
          color: Colors.green,
          backgroundColor: Colors.black,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final artist = artists[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[700],
                  child: artist.artistProfileUrl != null
                      ? ClipOval(
                          child: Image.network(
                            DatabaseService.resolveImageUrl(
                              artist.artistProfileUrl,
                              'artist_profiles',
                            )!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  artist.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ArtistDetailPage(db: widget.db, artist: artist),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
