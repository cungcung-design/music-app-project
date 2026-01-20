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
              // Avatar picker with modern overlay
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.green[400],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (widget.user.avatarUrl != null
                              ? NetworkImage(widget.user.avatarUrl!)
                                  as ImageProvider
                              : null),
                      child: _selectedImage == null && widget.user.avatarUrl == null
                          ? const Icon(Icons.person, size: 55, color: Colors.black54)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
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
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _modernField(controller: nameController, label: 'Name', icon: Icons.person),
              const SizedBox(height: 16),
              _modernField(controller: emailController, label: 'Email', icon: Icons.email, enabled: false),
              const SizedBox(height: 16),
        
              _modernField(controller: dobController, label: 'Date of Birth', icon: Icons.cake),
                const SizedBox(height: 16),
                    _modernField(controller: countryController, label: 'Country', icon: Icons.public),
              const SizedBox(height: 24),
               
              ElevatedButton(
                onPressed: _isLoading ? null : _updateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),

              const Text('Favorite Songs', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              FutureBuilder<List<Song>>(
                future: db.getUserFavorites(widget.user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)),
                    );
                  }

                  final favorites = snapshot.data ?? [];

                  if (favorites.isEmpty) {
                    return const Center(
                      child: Text('No favorite songs', style: TextStyle(color: Colors.grey)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.music_note, color: Colors.green),
                          title: Text(song.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(song.artistName ?? 'Unknown Artist', style: const TextStyle(color: Colors.grey)),
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
          ),
        ),
      ),
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
