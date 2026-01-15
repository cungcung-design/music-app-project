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
                backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                elevation: 0,
                centerTitle: false,
                leadingWidth: 60,
                titleSpacing: 0,
leading: Padding(
  padding: const EdgeInsets.only(left: 8),
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
        child: ClipOval(
          child: Container(
            width: 28,   // very small width
            height: 28,  // very small height
            color: Colors.grey[900],
            child: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                ? Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.person,
                    size: 16, // smaller icon
                    color: Colors.white,
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
                    Icon(
                      Icons.music_note,
                      color: Colors.green,
                      size: 40,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Spotify',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),

                /// TAB BAR
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

        /// BODY
        body: IndexedStack(
          index: selectedBottomIndex,
          children: [
            Stack(
              children: [
                TabBarView(
                  children: [
                    SuggestedPage(db: db),
                    SongsPage(db: db),
                    ArtistsPage(db: db),
                    AlbumsPage(db: db),
                  ],
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: MiniPlayer(),
                ),
              ],
            ),
            _pages[1],
            _pages[2],
            _pages[3],
          ],
        ),

        /// BOTTOM NAVIGATION
        bottomNavigationBar: BottomNavigationBar(
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
