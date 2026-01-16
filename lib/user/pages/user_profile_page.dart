import 'package:flutter/material.dart';
import 'package:project/user/pages/user_profile_view.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import '../../models/song.dart';
import 'profile_form_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<int> _likedSongsCount;
  late Future<int> _recentlyPlayedCount;

  @override
  void initState() {
    super.initState();
    _likedSongsCount = _getLikedSongsCount();
    _recentlyPlayedCount = _getRecentlyPlayedCount();
  }

  Future<int> _getLikedSongsCount() async {
    final db = DatabaseService();
    final favorites = await db.getFavorites();
    return favorites.length;
  }

  Future<int> _getRecentlyPlayedCount() async {
    final db = DatabaseService();
    final recentlyPlayed =
        await db.getRecentlyPlayedSongs(limit: 20); // Large limit to get all
    return recentlyPlayed.length;
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Your Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Profile Header - Fetches real data from Database
          FutureBuilder<Profile?>(
            future: db.getProfile(db.currentUser?.id ?? ''),
            builder: (context, snapshot) {
              final profile = snapshot.data;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserProfileViewDetail()),
                  );
                },
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: (profile?.avatarUrl != null &&
                          profile!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile?.avatarUrl == null)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  profile?.name ?? 'User Name',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("View Profile",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 16),
              );
            },
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10),

          // 2. Menu Options List
          Expanded(
            child: ListView(
              children: [
                FutureBuilder<int>(
                  future: _likedSongsCount,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildMenuTile(Icons.favorite, "Liked Songs",
                        subtitle: "$count songs");
                  },
                ),
                _buildMenuTile(Icons.playlist_play, "Your Playlists"),
                FutureBuilder<int>(
                  future: _recentlyPlayedCount,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildMenuTile(Icons.history, "Recently Played",
                        subtitle: "$count songs");
                  },
                ),
                _buildMenuTile(Icons.settings, "Settings"),
                _buildMenuTile(Icons.info_outline, "About"),
                const Divider(color: Colors.white10),

                // Logout Button
                _buildMenuTile(Icons.logout, "Logout", color: Colors.redAccent,
                    onTap: () {
                  // Add your logout logic here
                  print("User logged out");
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to keep code clean
  Widget _buildMenuTile(IconData icon, String title,
      {Color color = Colors.white, VoidCallback? onTap, String? subtitle}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }
}
