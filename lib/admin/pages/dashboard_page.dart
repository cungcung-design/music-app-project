import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          FutureBuilder<List<dynamic>>(
  future: Future.wait([
    db.getSongs(),
    db.getArtists(),
    db.getAlbums(),
  ]),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          snapshot.error.toString(),
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (!snapshot.hasData) {
      return const Text(
        'No data found',
        style: TextStyle(color: Colors.white),
      );
    }

    final songs = snapshot.data![0] as List;
    final artists = snapshot.data![1] as List;
    final albums = snapshot.data![2] as List;


              return Column(
                children: [
                  Card(
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.green),
                      title: const Text('Total Songs', style: TextStyle(color: Colors.white)),
                      trailing: Text(songs.length.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  Card(
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: const Text('Total Artists', style: TextStyle(color: Colors.white)),
                      trailing: Text(artists.length.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  Card(
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: const Icon(Icons.album, color: Colors.green),
                      title: const Text('Total Albums', style: TextStyle(color: Colors.white)),
                      trailing: Text(albums.length.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
