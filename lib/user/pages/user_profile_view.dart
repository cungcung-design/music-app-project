import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'edit_profile_page.dart';

class UserProfileViewDetail extends StatefulWidget {
  const UserProfileViewDetail({super.key});

  @override
  State<UserProfileViewDetail> createState() => _UserProfileViewDetail();
}

class _UserProfileViewDetail extends State<UserProfileViewDetail> {
  final DatabaseService db = DatabaseService();

  // Fetches current user profile data
  Future<Profile?> _fetchProfile() async {
    final user = db.currentUser;
    if (user == null) return null;
    return await db.getProfile(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () async {
              final profile = await _fetchProfile();
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(profile: profile),
                ),
              );

              if (updated == true) {
                setState(() {}); 
              }
            },
          )
        ],
      ),
      body: FutureBuilder<Profile?>(
        future: _fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          final profile = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                // 1. Profile Picture Section
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: (profile?.avatarUrl != null &&
                            profile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(
                            "${profile.avatarUrl}?v=${DateTime.now().millisecondsSinceEpoch}")
                        : null,
                    child: (profile?.avatarUrl == null ||
                            profile!.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 70, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  profile?.name ?? 'User Name',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // 2. Information Items
                _profileItem("Email", db.currentUser?.email ?? 'No email'),
                _profileItem("Display Name", profile?.name ?? 'Not set'),
                _profileItem(
                  "Date of Birth",
                  (profile?.dob != null && profile!.dob!.isNotEmpty)
                      ? DateFormat.yMMMEd().format(DateTime.parse(profile.dob!))
                      : 'Not set',
                ),
                _profileItem("Country", profile?.country ?? 'Not set'),
                
                // Add a simple Logout option at the bottom
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    // Add your logout logic here
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // UI helper for info cards
  Widget _profileItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}