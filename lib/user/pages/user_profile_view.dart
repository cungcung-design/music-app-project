import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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

  // Image update logic
  Future<void> _updateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final user = db.currentUser;
      if (user == null) return;

      // Generate unique filename
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'user_avatars/${user.id}/$fileName';

      // Upload to Supabase Storage
      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
          filePath, bytes,
          fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update profile in database
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      // Refresh UI
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: $e')),
        );
      }
    }
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
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
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
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _updateProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black, // Makes it pop
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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

                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Log Out",
                      style: TextStyle(color: Colors.redAccent)),
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
