import 'package:flutter/material.dart';
import 'package:project/admin/pages/manage_user_page.dart';
import 'dashboard_page.dart';
import 'manage_songs_page.dart';
import 'manage_artists_page.dart';
import 'manage_albums_page.dart';



class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ManageSongsPage(),
    ManageArtistsPage(),
    ManageAlbumsPage(),
    ManageUsersPage(),
  ];

  final List<String> titles = [
    'Dashboard',
    'Songs',
    'Artists',
    'Albums',
    'Users',
  ];

  // Logic to handle logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to exit?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 1. Clear your session/token here (e.g., AuthService().logout())
              // 2. Navigate to login and remove all previous routes
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
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
          // Logout Button
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Theme(
        // Makes the background solid black without the white line/shadow
        data: Theme.of(context).copyWith(canvasColor: Colors.black),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[600],
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.music_note_rounded), label: 'Songs'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Artists'),
            BottomNavigationBarItem(icon: Icon(Icons.album_rounded), label: 'Albums'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Users'),
          ],
        ),
      ),
    );
  }
}