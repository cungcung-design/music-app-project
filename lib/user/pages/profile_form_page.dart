import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'edit_profile_page.dart';
import '/home_page.dart';

class ProfileFormPage extends StatefulWidget {
  final bool afterSignup; 
  const ProfileFormPage({super.key, this.afterSignup = false});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final DatabaseService db = DatabaseService();

  // This function fetches the data from your database
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
        title: const Text("Public Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              // 1. Get current profile data
              final profile = await _fetchProfile();
              
              // 2. Go to Edit Page and wait for result
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(profile: profile),
                ),
              );

              // 3. If user saved changes, refresh this page
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
          // Show loading spinner while waiting for database
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final profile = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage("${profile.avatarUrl}?v=${DateTime.now().millisecondsSinceEpoch}")
                        : null,
                    child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.white70)
                        : null,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Profile Info Cards
                _profileItem("Email", db.currentUser?.email ?? 'No email found'),
                _profileItem("Name", profile?.name ?? 'Not set'),
                _profileItem(
                  "Date of Birth",
                  (profile?.dob != null && profile!.dob!.isNotEmpty)
                      ? DateFormat.yMMMEd().format(DateTime.parse(profile.dob!))
                      : 'Not set',
                ),
                _profileItem("Country", profile?.country ?? 'Not set'),

                const SizedBox(height: 40),

                // Bottom Buttons (Next/Back/Continue)
                if (widget.afterSignup)
                  _buildLargeButton("Continue", Colors.green, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const UserHomePage()),
                    );
                  })
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildLargeButton("Back", Colors.grey[800]!, () {
                          Navigator.pop(context);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLargeButton("Home", Colors.green, () {
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const UserHomePage()),
                          );
                        }, textColor: Colors.black),
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

  // Helper widget for information rows
  Widget _profileItem(String label, String value) {
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helper widget for buttons
  Widget _buildLargeButton(String text, Color bgColor, VoidCallback onPressed, {Color textColor = Colors.white}) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}