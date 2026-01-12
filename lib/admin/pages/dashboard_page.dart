import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            db.getSongsWithDetails(),
            db.getArtists(),
            db.getAlbums(),
            db.getAllUsers(),
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
            final users = snapshot.data![3] as List;

            return Column(
              children: [
                _dashboardCard(
                  icon: Icons.music_note,
                  label: 'Total Songs',
                  value: songs.length,
                ),
                _dashboardCard(
                  icon: Icons.person,
                  label: 'Total Artists',
                  value: artists.length,
                ),
                _dashboardCard(
                  icon: Icons.album,
                  label: 'Total Albums',
                  value: albums.length,
                ),
                _dashboardCard(
                  icon: Icons.people,
                  label: 'Total Users',
                  value: users.length,
                ),
                
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: Text(
          value.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
