import 'package:flutter/material.dart';
import 'package:project/user/pages/user_profile_view.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'profile_form_page.dart'; 

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({Key? key}) : super(key: key);

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
                  // Navigates to your detailed ProfileViewPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfileViewDetail()),
                  );
                },
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile?.avatarUrl == null)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  profile?.name ?? 'User Name',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("View Profile", style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              );
            },
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10),

          // 2. Menu Options List
          Expanded(
            child: ListView(
              children: [
                _buildMenuTile(Icons.favorite, "Liked Songs"),
                _buildMenuTile(Icons.playlist_play, "Your Playlists"),
                _buildMenuTile(Icons.history, "Recently Played"),
                _buildMenuTile(Icons.settings, "Settings"),
                _buildMenuTile(Icons.info_outline, "About"),
                const Divider(color: Colors.white10),
                
                // Logout Button
                _buildMenuTile(
                  Icons.logout, 
                  "Logout", 
                  color: Colors.redAccent,
                  onTap: () {
                    // Add your logout logic here
                    print("User logged out");
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to keep code clean
  Widget _buildMenuTile(IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }
}