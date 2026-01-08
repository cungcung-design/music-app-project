import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../utils/toast.dart';
import '../home_page.dart';

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

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = db.currentUser;
    if (user == null) return;

    try {
      final data = await db.getProfile(user.id);
      if (data != null) {
        nameController.text = data['name'] ?? '';
        dobController.text = data['dob'] ?? '';
        countryController.text = data['country'] ?? '';
        avatarUrl = data['avatar_url'];
        setState(() {});
      }
    } catch (e) {
      showToast(context, "Failed to load profile", isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) setState(() => selectedImage = File(image.path));
    } catch (e) {
      showToast(context, "Failed to pick image", isError: true);
      print("Image pick error: $e");
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
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
                      ),
                      const SizedBox(height: 20),

                      const Text("Full Name", style: TextStyle(color: Colors.white70)),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Enter your name",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Date of Birth", style: TextStyle(color: Colors.white70)),
                      TextField(
                        controller: dobController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "YYYY-MM-DD",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),

                      const Text("Country / Region", style: TextStyle(color: Colors.white70)),
                      TextField(
                        controller: countryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Enter your country",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("BACK"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (user == null) return;

                        try {
                          if (nameController.text.isEmpty ||
                              dobController.text.isEmpty ||
                              countryController.text.isEmpty) {
                            showToast(context, "Please fill all fields", isError: true);
                            return;
                          }

                          String? uploadedUrl = avatarUrl;
                          if (selectedImage != null) {
                            uploadedUrl = await db.uploadAvatar(selectedImage!, user.id);
                          }

                          await db.updateProfile(
                            userId: user.id,
                            name: nameController.text.trim(),
                            dob: dobController.text.trim(),
                            country: countryController.text.trim(),
                            avatarUrl: uploadedUrl,
                          );

                          showToast(context, "Profile saved successfully");

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        } catch (e) {
                          print("Profile save error: $e");
                          showToast(context, "Failed to save profile", isError: true);
                        }
                      },
                      child: const Text("NEXT"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
