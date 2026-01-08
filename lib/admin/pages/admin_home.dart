import 'package:flutter/material.dart';
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
  ];

  final List<String> titles = [
    'Dashboard',
    'Songs',
    'Artists',
    'Albums',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor: Colors.black,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() => selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artists'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
        ],
      ),
    );
  }
}
