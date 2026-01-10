import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'user/pages/suggested_page.dart';
// Import your new pages
import 'user/pages/favourite_page.dart';
import 'user/pages/search_page.dart';
import 'user/pages/profile_page.dart';
import 'user/widgets/mini_player.dart';
import 'user/widgets/tab_widgets.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int selectedIndex = 0;
  int selectedBottomIndex = 0; // For BottomNavigationBar
  final DatabaseService db = DatabaseService();

  // List of pages for the Bottom Navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SuggestedPage(db: db), // Home
      FavoritesPage(db: db), // Favorites
      const SearchPage(), // Search
      const ProfilePage(), // Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: selectedBottomIndex == 0
            ? AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: const Icon(Icons.music_note, color: Colors.green),
                title: const Text(
                  'Spotify',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: const TabBar(
                  indicatorColor: Colors.green,
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Suggested'),
                    Tab(text: 'Songs'),
                    Tab(text: 'Artists'),
                    Tab(text: 'Albums'),
                  ],
                ),
              )
            : null,
        body: IndexedStack(
          index: selectedBottomIndex,
          children: [
            // Home: Tab view with MiniPlayer
            Stack(
              children: [
                TabBarView(
                  children: [
                    SuggestedTab(db: db),
                    SongsTab(db: db),
                    ArtistsTab(db: db),
                    AlbumsTab(db: db),
                  ],
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: MiniPlayer(),
                ),
              ],
            ),
            // Favorites
            Container(color: Colors.black, child: _pages[1]),
            // Search
            Container(color: Colors.black, child: _pages[2]),
            // Profile
            Container(color: Colors.black, child: _pages[3]),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedBottomIndex,
          onTap: (index) {
            setState(() {
              selectedBottomIndex = index;
            });
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
