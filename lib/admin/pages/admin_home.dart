import 'package:flutter/material.dart';
import 'package:project/admin/pages/manage_user_page.dart';
import 'dashboard_page.dart';
import 'manage_songs_page.dart';
import 'manage_artists_page.dart';
import 'manage_albums_page.dart';
import 'manage_user_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Matching your theme
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor: Colors.black,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Better for 4+ items
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() => selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artists'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}
