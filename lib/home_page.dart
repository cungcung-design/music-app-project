import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'user/pages/suggested_page.dart';
import 'user/pages/favourite_page.dart';
import 'user/pages/search_page.dart';
import 'user/pages/user_profile_page.dart';
import 'user/pages/user_profile_view.dart';
import 'user/widgets/mini_player.dart';
import 'user/widgets/tab_widgets.dart';
import 'models/profile.dart'; // Import your profile model

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int selectedIndex = 0;
  int selectedBottomIndex = 0;
  final DatabaseService db = DatabaseService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SuggestedPage(db: db),
      FavoritesPage(db: db),
      const SearchPage(),
      const UserProfilePage(),
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
                centerTitle: false,
                leadingWidth: 100, 
                leading: Row(
                  children: [
                    const SizedBox(width: 12),
                    // --- USER PROFILE PIC ---
                    FutureBuilder<Profile?>(
                      future: db.getProfile(db.currentUser?.id ?? ''),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserProfileViewDetail(),
                              ),
                            ).then(
                              (value) => setState(() {}),
                            ); // Refresh if updated
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[900],
                            backgroundImage:
                                (profile?.avatarUrl != null &&
                                    profile!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: (profile?.avatarUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.music_note, color: Colors.green, size: 28),
                  ],
                ),
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
                  isScrollable: false,
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
            Container(color: Colors.black, child: _pages[1]),
            Container(color: Colors.black, child: _pages[2]),
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
          type: BottomNavigationBarType.fixed, // Better for 4+ items
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
