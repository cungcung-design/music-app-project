import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'edit_profile_page.dart';

class UserProfileViewDetail extends StatefulWidget {
  const UserProfileViewDetail({super.key});

  @override
  State<UserProfileViewDetail> createState() => _UserProfileViewDetailState();
}

class _UserProfileViewDetailState extends State<UserProfileViewDetail> {
  final DatabaseService db = DatabaseService();
  bool _isUploading = false;

  Future<Profile?> _fetchProfile() async {
    final user = db.currentUser;
    if (user == null) return null;
    return await db.getProfile(user.id);
  }

  Future<void> _updateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      final user = db.currentUser;
      if (user == null) return;

      setState(() => _isUploading = true);

      try {
        final bytes = await image.readAsBytes();
        final profile = await _fetchProfile();

        final newAvatarPath = await db.uploadAvatar(
          user.id,
          bytes,
          fileExtension: image.path.split('.').last,
        );

        await db.updateProfile(
          userId: user.id,
          name: profile?.name ?? 'User',
          avatarPath: newAvatarPath,
          dob: profile?.dob,
          country: profile?.country,
        );

        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Force refresh the profile data
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // Helper with Bordered Container and ListTile
  Widget _borderedProfileItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1), // The Border
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 24),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () async {
              final profile = await _fetchProfile();
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfilePage(profile: profile)),
              );
              if (updated == true) setState(() {});
            },
          )
        ],
      ),
      body: FutureBuilder<Profile?>(
        future: _fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isUploading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }
          final profile = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[900],
                        backgroundImage: (profile?.avatarUrl != null &&
                                profile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(
                                "${profile.avatarUrl}?v=${DateTime.now().millisecondsSinceEpoch}")
                            : null,
                        child: (profile?.avatarUrl == null ||
                                profile!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _updateProfileImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Bordered Information Items
                _borderedProfileItem(
                  title: "NAME",
                  subtitle: profile?.name ?? 'Not set',
                  icon: Icons.person,
                ),
                _borderedProfileItem(
                  title: "EMAIL",
                  subtitle: db.currentUser?.email ?? 'No email',
                  icon: Icons.email,
                ),
                _borderedProfileItem(
                  title: "DATE OF BIRTH",
                  subtitle: (profile?.dob != null && profile!.dob!.isNotEmpty)
                      ? DateFormat.yMMMMd().format(DateTime.parse(profile.dob!))
                      : 'Not set',
                  icon: Icons.cake,
                ),
                _borderedProfileItem(
                  title: "COUNTRY",
                  subtitle: profile?.country ?? 'Not set',
                  icon: Icons.location_on,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
