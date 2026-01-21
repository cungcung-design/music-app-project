import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'user/pages/suggested_page.dart';
import 'user/pages/favourite_page.dart';
import 'user/pages/search_page.dart';
import 'user/pages/user_profile_page.dart';
import 'user/pages/user_profile_view.dart';
import 'user/pages/songs_page.dart';
import 'user/pages/artists_page.dart';
import 'user/pages/albums_page.dart';
import 'user/widgets/mini_player.dart';
import 'models/profile.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int selectedBottomIndex = 0;
  final DatabaseService db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: selectedBottomIndex == 0
            ? AppBar(
                backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                elevation: 0,
                centerTitle: false,
                leadingWidth: 50,
                titleSpacing: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: FutureBuilder<Profile?>(
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
                          ).then((_) => setState(() {}));
                        },
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[900],
                              border:
                                  Border.all(color: Colors.white10, width: 0.5),
                            ),
                            child: ClipOval(
                              child: (profile?.avatarUrl != null &&
                                      profile!.avatarUrl!.isNotEmpty)
                                  ? Image.network(
                                      profile.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person,
                                                  size: 18,
                                                  color: Colors.white),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.music_note, color: Colors.green, size: 30),
                    SizedBox(width: 6),
                    Text(
                      'Spotify',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                // actions: [
                //   IconButton(
                //     icon: const Icon(Icons.refresh, color: Colors.white),
                //     onPressed: () {
                //       setState(() {});
                //     },
                //   ),
                // ],
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

        /// BODY - Uses IndexedStack to keep page states alive
        body: IndexedStack(
          index: selectedBottomIndex,
          children: [
            // Index 0: Home Tab with sub-tabs
            TabBarView(
              children: [
                SuggestedPage(db: db),
                SongsPage(db: db),
                ArtistsPage(db: db),
                AlbumsPage(db: db),
              ],
            ),
            FavoritesPage(db: db),
            const SearchPage(),
            const UserProfilePage(),
          ],
        ),

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            BottomNavigationBar(
              currentIndex: selectedBottomIndex,
              onTap: (index) {
                setState(() {
                  selectedBottomIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.favorite), label: 'Favorites'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
