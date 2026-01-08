import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'add_edit_artist_page.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({Key? key}) : super(key: key);

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  final DatabaseService db = DatabaseService();
  List<Map<String, dynamic>> artists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  Future<void> fetchArtists() async {
    if (mounted) setState(() => loading = true);
    try {
      final data = await db.getArtists();
      if (mounted) setState(() => artists = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching artists: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void deleteArtist(String id) async {
    try {
      await db.deleteArtist(id);
      fetchArtists();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Artist deleted ✅')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: artist['profile_url'] != null
                        ? NetworkImage(artist['profile_url'])
                        : null,
                    backgroundColor: Colors.grey[800],
                  ),
                  title: Text(
                    artist['name'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    artist['bio'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditArtistPage(artist: artist),
                            ),
                          ).then((_) => fetchArtists());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteArtist(artist['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditArtistPage()),
          ).then((_) => fetchArtists());
        },
      ),
    );
  }
}
