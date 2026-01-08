import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'user/pages/suggested_page.dart';
import 'user/pages/songs_page.dart';
import 'user/pages/artists_page.dart';
import 'user/pages/albums_page.dart';



class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late TabController tabController;
  final DatabaseService db = DatabaseService();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() => selectedIndex = tabController.index);
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.music_note, color: Colors.green),
        title: const Text(
          'Spotify',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Suggested'),
            Tab(text: 'Songs'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          SuggestedPage(db: db),
          SongsPage(db: db),
          ArtistsPage(db: db),
          AlbumsPage(db: db),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => tabController.animateTo(index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artists'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
        ],
      ),
    );
  }
}
