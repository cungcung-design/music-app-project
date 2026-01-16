import 'package:flutter/material.dart';
import 'package:project/admin/pages/manage_user_page.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player_buttom.dart'; 
import 'dashboard_page.dart';
import 'manage_songs_page.dart';
import 'manage_artists_page.dart';
import 'manage_albums_page.dart';
import 'set_admin_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;
  int refreshCounter = 0;

  final AudioPlayerService playerService = AudioPlayerService();

  List<Widget> get pages => [
        DashboardPage(
            key: selectedIndex == 0 ? ValueKey(refreshCounter) : null),
        ManageSongsPage(
            key: selectedIndex == 1 ? ValueKey(refreshCounter) : null),
        ManageArtistsPage(
          key: selectedIndex == 2 ? ValueKey(refreshCounter) : null,
        ),
        ManageAlbumsPage(
            key: selectedIndex == 3 ? ValueKey(refreshCounter) : null),
        ManageUsersPage(
            key: selectedIndex == 4 ? ValueKey(refreshCounter) : null),
      ];

  final List<String> titles = [
    'Dashboard',
    'Songs',
    'Artists',
    'Albums',
    'Users',
  ];

  void _handleRefresh() {
    setState(() => refreshCounter++);
  }

  void _handleLogout() {
    // Stop music on logout
    playerService.stopAndClear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to exit?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SetAdminPage()),
            ),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
          ),
          IconButton(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // --- THE PERSISTENT PLAYER LOGIC ---
      body: Stack(
        children: [
          // The actual page content
          pages[selectedIndex],

          // The Mini Player anchored to the bottom
          Positioned(bottom: 0, left: 0, right: 0, child: GlobalMiniPlayer()),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.black),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[600],
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note_rounded),
              label: 'Songs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Artists',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.album_rounded),
              label: 'Albums',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}
