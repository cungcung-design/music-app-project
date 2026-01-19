import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Add this
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import '/home_page.dart';

class ProfileFormPage extends StatefulWidget {
  final bool afterSignup;
  final String? initialName;
  const ProfileFormPage(
      {super.key, this.afterSignup = false, this.initialName});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final DatabaseService db = DatabaseService();

  final nameController = TextEditingController();
  final countryController = TextEditingController();
  final dobController = TextEditingController();

  DateTime? _selectedDate;
  String? _imageUrl; // To store the uploaded image URL
  bool _isLoading = false;
  bool _isFetching = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final profile = await db.getProfile(db.currentUser!.id);
    if (profile != null) {
      nameController.text = profile.name ?? '';
      countryController.text = profile.country ?? '';
      _imageUrl = profile.avatarUrl;
      if (profile.dob != null) {
        _selectedDate = DateTime.parse(profile.dob!);
        dobController.text = DateFormat.yMMMMd().format(_selectedDate!);
      }
    } else if (widget.afterSignup && widget.initialName != null) {
      // Pre-fill name from signup if no existing profile
      nameController.text = widget.initialName!;
    }
    setState(() => _isFetching = false);
  }

  // --- Image Upload Logic ---
  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final user = db.currentUser;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'user_avatars/${user!.id}/$fileName';
      final bytes = await image.readAsBytes();

      // Upload to Storage
      await Supabase.instance.client.storage.from('profiles').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get Public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);

      setState(() {
        _imageUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = db.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'name': nameController.text.trim(),
        'country': countryController.text.trim(),
        'dob': _selectedDate?.toIso8601String(),
        'avatar_url': _imageUrl, // Save image URL to DB
      });

      if (mounted) {
        if (widget.afterSignup) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const UserHomePage()));
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        dobController.text = DateFormat.yMMMMd().format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
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
            // --- Profile Image Upload Section ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[900],
                    backgroundImage:
                        (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage(_imageUrl!)
                            : null,
                    child: (_imageUrl == null || _imageUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.white70)
                        : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.camera_alt,
                            color: Colors.black, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildInputField("Full Name", nameController, icon: Icons.person),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildInputField("Date of Birth", dobController,
                    icon: Icons.cake),
              ),
            ),
            const SizedBox(height: 16),

            _buildInputField("Country", countryController, icon: Icons.public),

            const SizedBox(height: 40),

            _isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : _buildLargeButton(
                    widget.afterSignup ? "Save & Continue" : "Update Profile",
                    Colors.green,
                    _saveProfile,
                    textColor: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green, size: 20),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeButton(String text, Color bgColor, VoidCallback onPressed,
      {Color textColor = Colors.white}) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
