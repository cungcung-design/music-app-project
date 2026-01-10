import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'user_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return FutureBuilder<Profile?>(
      future: db.getUserProfile(), // Fetch current user's profile
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'Profile not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final profile = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                profile.email,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              if (profile.dob != null && profile.dob!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "DOB: ${profile.dob}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
              if (profile.country != null && profile.country!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "Country: ${profile.country}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfilePage()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}
