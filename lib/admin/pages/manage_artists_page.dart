import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../pages/album_detail_page.dart';
import '../widgets/artists_dialog.dart';
import '../../utils/toast.dart';

class ManageArtistsPage extends StatefulWidget {
  const ManageArtistsPage({super.key});

  @override
  State<ManageArtistsPage> createState() => _ManageArtistsPageState();
}

class _ManageArtistsPageState extends State<ManageArtistsPage> {
  final DatabaseService db = DatabaseService();
  late Future<List<Artist>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  void _loadArtists() {
    _artistsFuture = db.getArtists();
  }

  void _showAddArtistDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => ArtistDialog(db: db),
    );
    if (result == true) {
      _loadArtists();
      setState(() {});
    }
  }

  void _showEditArtistDialog(Artist artist) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ArtistDialog(db: db, artist: artist),
    );
    if (result == true) {
      _loadArtists();
      setState(() {});
    }
  }

  void _showDeleteArtistDialog(Artist artist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Artist',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${artist.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await db.deleteArtist(artist.id);
        showToast(context, 'Artist deleted successfully', isError: false);
        _loadArtists();
        setState(() {});
      } catch (e) {
        showToast(context, 'Failed to delete artist: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddArtistDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder<List<Artist>>(
        future: _artistsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );

          final artists = snapshot.data!
            ..sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundImage: artist.artistProfileUrl != null
                        ? NetworkImage(artist.artistProfileUrl!)
                        : null,
                    child: artist.artistProfileUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          artist.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditArtistDialog(artist),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteArtistDialog(artist),
                      ),
                    ],
                  ),
                  children: [_buildAlbumList(artist.id)],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumList(String artistId) {
    return FutureBuilder<List<Album>>(
      future: db.getAlbumsByArtist(artistId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Colors.green);

        final albums = snapshot.data!;
        if (albums.isEmpty)
          return const ListTile(
            title: Text(
              "No albums found",
              style: TextStyle(color: Colors.grey),
            ),
          );

        return Column(
          children: albums
              .map(
                (album) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      album.albumProfileUrl ?? '',
                      width: 35,
                      height: 35,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.album, color: Colors.green),
                    ),
                  ),
                  title: Text(
                    album.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),

                  // --- WHEN CLICKING ALBUM ---
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailPage(album: album),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
