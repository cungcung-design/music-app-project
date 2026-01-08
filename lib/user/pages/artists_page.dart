import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';

class ArtistsPage extends StatefulWidget {
  final DatabaseService db;
  const ArtistsPage({super.key, required this.db});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  List<Artist> artists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadArtists();
  }

  Future<void> loadArtists() async {
    final data = await widget.db.getArtists();
    setState(() {
      artists = data.map((e) => Artist.fromMap(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final artist = artists[index];
        return ListTile(
          tileColor: Colors.grey[850],
          leading: CircleAvatar(
            backgroundColor: Colors.grey[700],
            child: artist.profileUrl != null && artist.profileUrl!.isNotEmpty
                ? ClipOval(child: Image.network(artist.profileUrl!, width: 40, height: 40, fit: BoxFit.cover))
                : const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(artist.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(artist.bio ?? '', style: const TextStyle(color: Colors.grey)),
        );
      },
    );
  }
}
