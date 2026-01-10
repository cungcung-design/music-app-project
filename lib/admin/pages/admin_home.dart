import 'package:flutter/material.dart';
import 'package:project/admin/pages/manage_user_page.dart';
import '../../services/database_seeder.dart';
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
  bool isSyncing = false; // To track if seeding is in progress

  final List<Widget> pages = const [
    DashboardPage(),
    ManageSongsPage(),
    ManageArtistsPage(),
    ManageAlbumsPage(),
    ManageUsersPage()
  ];

  final List<String> titles = [
    'Dashboard',
    'Songs',
    'Artists',
    'Albums',
      'Users',

  ];

  // Function to handle the seeding process
  Future<void> handleSync() async {
    setState(() => isSyncing = true);
    
    // Show a snackbar to let the user know it started
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Syncing Storage files to Database..."), duration: Duration(seconds: 1)),
    );

    try {
      await seedDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sync Complete! ✅"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Matching your theme
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor: Colors.black,
        actions: [
          // The Sync Button
          isSyncing 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
              )
            : IconButton(
                icon: const Icon(Icons.sync, color: Colors.green),
                tooltip: "Sync Storage to DB",
                onPressed: handleSync,
              ),
        ],
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artists'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(
  icon: Icon(Icons.people),
  label: 'Users',
),

        ],
      ),
    );
  }
}