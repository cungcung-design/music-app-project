import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';
import '../../models/profile.dart';
import '/home_page.dart';

class EditProfilePage extends StatefulWidget {
  final Profile? profile;
  final bool isNewUser; // true = after signup

  const EditProfilePage({super.key, this.profile, this.isNewUser = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final db = DatabaseService();

  late TextEditingController nameController;
  late TextEditingController dobController;
  late TextEditingController countryController;

  File? selectedImage;
  String? avatarUrl;
  bool isSaving = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile?.name ?? '');
    dobController = TextEditingController(
        text: widget.profile?.dob != null
            ? DateFormat.yMMMEd().format(DateTime.parse(widget.profile!.dob!))
            : '');
    countryController =
        TextEditingController(text: widget.profile?.country ?? '');
    avatarUrl = widget.profile?.avatarUrl;
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => selectedImage = File(image.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.profile?.dob != null
          ? DateTime.parse(widget.profile!.dob!)
          : DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text = DateFormat.yMMMEd().format(picked);
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
      String? uploadedAvatar = avatarUrl;
      if (selectedImage != null) {
        uploadedAvatar = await db.uploadAvatar(selectedImage!, user.id);
      }

      await db.updateProfile(
        userId: user.id,
        name: nameController.text.trim(),
        dob: DateFormat('yyyy-MM-dd')
            .format(DateFormat.yMMMEd().parse(dobController.text)),
        country: countryController.text.trim(),
        avatarPath: uploadedAvatar,
      );

      showToast(context, "Profile saved successfully");

      if (widget.isNewUser) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const UserHomePage()));
      } else {
        Navigator.pop(context, true); // refresh ProfilePage
      }
    } catch (e) {
      showToast(context, "Failed to save profile: $e", isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () {
    Navigator.pop(context);
  },
),
        title: Text(widget.isNewUser ? "Complete Profile" : "Edit Profile" , style: TextStyle(color:Colors.white),),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
       GestureDetector(
  onTap: _pickImage, // optional: you can remove if you only want icon to change
  child: Stack(
    children: [
      CircleAvatar(
        radius: 55,
        backgroundColor: Colors.grey[800],
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : avatarUrl != null
                ? NetworkImage(
                    "$avatarUrl?v=${DateTime.now().millisecondsSinceEpoch}")
                as ImageProvider
                : null,
        child: selectedImage == null && avatarUrl == null
            ? const Icon(Icons.person, size: 50, color: Colors.white70)
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
            border: Border.all(color: Colors.black, width: 2),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
        ),
      ),
 )
    ],
  ),
),

            const SizedBox(height: 30),
            _inputField("Full Name", nameController),
            const SizedBox(height: 16),
            _inputField("Date of Birth", dobController,
                readOnly: true, onTap: _pickDate),
            const SizedBox(height: 16),
            _inputField("Country", countryController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text("SAVE"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[900],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
