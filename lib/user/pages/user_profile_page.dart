import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';
import '../../../user/pages/profile_view_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final db = DatabaseService();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final countryController = TextEditingController();

  File? selectedImage;
  String? avatarUrl;
  String? avatarPath;
  bool isSaving = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = db.currentUser;
    if (user == null) return;

    final data = await db.getProfile(user.id);
    if (data != null) {
      nameController.text = data.name ?? '';
      dobController.text = data.dob ?? '';
      countryController.text = data.country ?? '';
      avatarUrl = data.avatarUrl;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = db.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[800],
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : avatarUrl != null
                    ? NetworkImage(avatarUrl!) as ImageProvider
                    : null,
                child: selectedImage == null && avatarUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            _input("Full Name", nameController),
            const SizedBox(height: 16),

            _input(
              "Date of Birth",
              dobController,
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            _input("Country", countryController),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (user == null) return;

                        if (nameController.text.isEmpty ||
                            dobController.text.isEmpty ||
                            countryController.text.isEmpty) {
                          showToast(
                            context,
                            "Please fill all fields",
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isSaving = true);

                        try {
                          String? uploadedAvatar = avatarUrl;

                          if (selectedImage != null) {
                            uploadedAvatar = await db.uploadAvatar(
                              selectedImage!,
                              user.id,
                            );
                          }

                          await db.updateProfile(
                            userId: user.id,
                            name: nameController.text.trim(),
                            dob: dobController.text.trim(),
                            country: countryController.text.trim(),
                            avatarPath: uploadedAvatar,
                          );

                          showToast(context, "Profile saved");

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileViewPage(),
                            ),
                          );
                        } catch (e) {
                          showToast(
                            context,
                            "Failed to save profile",
                            isError: true,
                          );
                        } finally {
                          setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text("SAVE"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
