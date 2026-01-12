import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../widgets/artists_dialog.dart';

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

  Future<void> _openArtistDialog([Artist? artist]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ArtistDialog(db: db, artist: artist),
    );

    if (result == true) {
      setState(() => _loadArtists()); // Refresh after add/edit
    }
  }

  Future<void> _deleteArtist(String id) async {
    await db.deleteArtist(id);
    setState(() => _loadArtists()); // Refresh after delete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Artists'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _loadArtists()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _openArtistDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Artist>>(
        future: _artistsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final artists = snapshot.data!;
          if (artists.isEmpty) {
            return const Center(
              child: Text(
                'No artists found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];

              return Card(
                color: Colors.grey[900],
                child: ExpansionTile(
                  collapsedIconColor: Colors.white,
                  iconColor: Colors.green,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    backgroundImage: artist.artistProfileUrl != null
                        ? NetworkImage(artist.artistProfileUrl!)
                        : null,
                    child: artist.artistProfileUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    artist.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    artist.bio,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openArtistDialog(artist),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteArtist(artist.id),
                      ),
                    ],
                  ),
                  // -------------------- Albums Loop --------------------
                  children: [
                    FutureBuilder<List<Album>>(
                      future: db.getAlbumsByArtist(artist.id),
                      builder: (context, albumSnap) {
                        if (!albumSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          );
                        }

                        final albums = albumSnap.data!;
                        if (albums.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No albums',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: albums.map((album) {
                            return ListTile(
                              leading: Image.network(
                                album.albumProfileUrl ?? '',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.album,
                                      color: Colors.green,
                                    ),
                              ),
                              title: Text(
                                album.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
