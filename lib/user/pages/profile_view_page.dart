import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'user_profile_page.dart';
import '../../home_page.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  Future<Profile?> _loadProfile() async {
    final db = DatabaseService();
    final user = db.currentUser;
    if (user == null) return null;
    return await db.getProfile(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfilePage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Profile?>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(
                          "${profile!.avatarUrl}?v=${DateTime.now().millisecondsSinceEpoch}",
                        )
                      : null,
                  child: profile?.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white70,
                        )
                      : null,
                ),
                const SizedBox(height: 30),
                _info("Email", db.currentUser?.email ?? ''),
                _info("Name", profile?.name ?? ''),
                _info("DOB", profile?.dob ?? 'Not set'),
                _info("Country", profile?.country ?? 'Not set'),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserHomePage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
