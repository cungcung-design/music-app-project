import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';

class UserDetailPage extends StatefulWidget {
  final Profile user;
  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final DatabaseService db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController countryController;
  late TextEditingController dobController;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    countryController = TextEditingController(text: widget.user.country ?? '');
    dobController = TextEditingController(text: widget.user.dob ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    countryController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarPath;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        avatarPath = await db.uploadAvatar(widget.user.id, bytes,
            fileExtension: _selectedImage!.path.split('.').last);
      }

      await db.updateProfile(
        userId: widget.user.id,
        name: nameController.text.trim(),
        dob: dobController.text.trim(),
        country: countryController.text.trim(),
        avatarPath: avatarPath,
      );

      showToast(context, 'User updated successfully');
      Navigator.pop(context, true);
    } catch (e) {
      showToast(context, e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AvatarPicker(
                selectedImage: _selectedImage,
                user: widget.user,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 24),
              UserFormFields(
                nameController: nameController,
                emailController: emailController,
                dobController: dobController,
                countryController: countryController,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
              FavoriteSongsSection(userId: widget.user.id),
            ],
          ),
        ),
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  final File? selectedImage;
  final Profile user;
  final VoidCallback onPickImage;

  const AvatarPicker({
    super.key,
    required this.selectedImage,
    required this.user,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.green[400],
            backgroundImage: selectedImage != null
                ? FileImage(selectedImage!)
                : (user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                    : null),
            child: selectedImage == null && user.avatarUrl == null
                ? const Icon(Icons.person, size: 55, color: Colors.black54)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.edit, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController dobController;
  final TextEditingController countryController;

  const UserFormFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.dobController,
    required this.countryController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _modernField(
            controller: nameController, label: 'Name', icon: Icons.person),
        const SizedBox(height: 16),
        _modernField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email,
            enabled: false),
        const SizedBox(height: 16),
        _modernField(
            controller: dobController,
            label: 'Date of Birth',
            icon: Icons.cake),
        const SizedBox(height: 16),
        _modernField(
            controller: countryController,
            label: 'Country',
            icon: Icons.public),
      ],
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey[850],
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class FavoriteSongsSection extends StatelessWidget {
  final String userId;

  const FavoriteSongsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favorite Songs',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Song>>(
          future: DatabaseService().getUserFavorites(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red)),
              );
            }

            final favorites = snapshot.data ?? [];

            if (favorites.isEmpty) {
              return const Center(
                child: Text('No favorite songs',
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final song = favorites[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.music_note, color: Colors.green),
                    title: Text(song.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(song.artistName ?? 'Unknown Artist',
                        style: const TextStyle(color: Colors.grey)),
                    trailing: Icon(Icons.play_arrow, color: Colors.green),
                    onTap: () {
                      // Add action for playing song if needed
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
