import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';
import 'profile_form_page.dart';
import '/home_page.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final db = DatabaseService();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final countryController = TextEditingController();
  File? selectedImage;
  bool isSaving = false;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => selectedImage = File(image.path));
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

  Future<void> _saveProfile() async {
    final user = db.currentUser;
    if (user == null) return;

    if (nameController.text.isEmpty ||
        dobController.text.isEmpty ||
        countryController.text.isEmpty) {
      showToast(context, "Please fill all fields", isError: true);
      return;
    }

    setState(() => isSaving = true);
    try {
      String? avatarUrl;
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        avatarUrl = await db.uploadAvatar(user.id, bytes,
            fileExtension: selectedImage!.path.split('.').last);
      }

      await db.updateProfile(
        userId: user.id,
        name: nameController.text.trim(),
        dob: dobController.text.trim(),
        country: countryController.text.trim(),
        avatarPath: avatarUrl,
      );

      showToast(context, "Profile saved successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserHomePage()),
      );
    } catch (e) {
      showToast(context, "Failed to save profile", isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    selectedImage != null ? FileImage(selectedImage!) : null,
                child: selectedImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _input("Full Name", nameController),
            const SizedBox(height: 16),
            _input("Date of Birth", dobController,
                readOnly: true, onTap: _pickDate),
            const SizedBox(height: 16),
            _input("Country", countryController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE PROFILE"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}
