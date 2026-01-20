import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/auth/login_page.dart';
import '../../services/database_service.dart';
import '../../home_page.dart';
import 'package:intl/intl.dart';

class ProfileFormPage extends StatefulWidget {
  final bool afterSignup;
  final String? initialName;
  final String? initialUserId;

  const ProfileFormPage({
    super.key,
    this.afterSignup = false,
    this.initialName,
    this.initialUserId,
  });

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final db = DatabaseService();

  final nameController = TextEditingController();
  final countryController = TextEditingController();
  final dobController = TextEditingController();

  String? _imagePath; // path in Supabase
  String? _imageUrl; // public URL
  DateTime? _selectedDate;
  String? _userId; // Store user ID from loaded profile

  bool _loading = false;
  bool _uploading = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _fetching = true);

    // Use initialUserId if provided (from signup), otherwise get from currentUser
    String? userId = widget.initialUserId;

    if (userId == null) {
      final user = db.currentUser;
      if (user == null) {
        if (mounted) setState(() => _fetching = false);
        return;
      }
      userId = user.id;
    }

    // Store user ID for later use
    _userId = userId;

    nameController.text = widget.initialName ?? '';

    try {
      final profile = await db.getProfile(userId);
      if (profile != null) {
        // Use profile name if available, otherwise keep initialName
        nameController.text = profile.name ?? widget.initialName ?? '';
        countryController.text = profile.country ?? '';
        _imagePath = profile.avatarPath;
        if (_imagePath != null) {
          _imageUrl = db.getStorageUrl(_imagePath!, 'profiles');
        }
        if (profile.dob != null) {
          _selectedDate = DateTime.tryParse(profile.dob!);
          if (_selectedDate != null) {
            dobController.text = DateFormat.yMMMMd().format(_selectedDate!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    String? userId = _userId ?? db.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to upload image")));
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last;

      final newPath = await db.uploadAvatar(
        userId,
        bytes,
        fileExtension: extension,
      );

      setState(() {
        _imagePath = newPath;
        _imageUrl = db.getStorageUrl(newPath, 'profiles');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Image uploaded successfully!",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Name is required")));
      return;
    }

    // Use stored user ID, or get it from currentUser as fallback
    String? userId = _userId ?? db.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to save profile")));
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await db.updateProfile(
        userId: userId,
        name: nameController.text.trim(),
        country: countryController.text.trim(),
        dob: _selectedDate?.toIso8601String(),
        avatarPath: _imagePath,
      );

      if (!mounted) return;

      if (widget.afterSignup) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const LoginPage()),
);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Save failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.afterSignup ? "Setup Profile" : "Edit Profile",
            style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 30),
            _buildTextField("Full Name", nameController, Icons.person),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildTextField("Country", countryController, Icons.public),
            const SizedBox(height: 40),
            _loading
                ? const CircularProgressIndicator(color: Colors.green)
                : _buildButton(
                    widget.afterSignup ? "Save & Continue" : "Update Profile",
                    _saveProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[900],
            backgroundImage:
                _imageUrl != null ? NetworkImage(_imageUrl!) : null,
            child: _imageUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.white70)
                : null,
          ),
          if (_uploading)
            const Positioned.fill(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _uploading ? null : _pickAndUploadAvatar,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.camera_alt, color: Colors.black, size: 18),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextField(
      controller: dobController,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
        hintText: "Date of Birth",
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            dobController.text = DateFormat.yMMMMd().format(date);
          });
        }
      },
    );
  }
}
