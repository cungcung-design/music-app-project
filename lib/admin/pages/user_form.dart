import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../utils/toast.dart';
import 'package:uuid/uuid.dart';

class UserFormPage extends StatefulWidget {
  final Profile? user;
  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final DatabaseService db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController countryController;
  late TextEditingController dobController;

  File? _selectedImage;
  bool _isLoading = false;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?.name ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    countryController = TextEditingController(text: widget.user?.country ?? '');
    dobController = TextEditingController(text: widget.user?.dob ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarPath;

      if (_selectedImage != null) {
        // If editing, use existing user id, otherwise generate new
        final userId = isEdit ? widget.user!.id : const Uuid().v4();
        final bytes = await _selectedImage!.readAsBytes();
        avatarPath = await db.uploadAvatar(userId, bytes,
            fileExtension: _selectedImage!.path.split('.').last);
      }

      if (isEdit) {
        await db.updateProfile(
          userId: widget.user!.id,
          name: nameController.text.trim(),
          dob: dobController.text.trim(),
          country: countryController.text.trim(),
          avatarPath: avatarPath,
        );
        showToast(context, 'User updated successfully');
      } else {
        await db.addUser(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          country: countryController.text.trim(),
          avatarPath: avatarPath,
        );
        showToast(context, 'User added successfully');
      }

      if (!mounted) return;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Avatar picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.user?.avatarUrl != null
                          ? NetworkImage(widget.user!.avatarUrl!)
                              as ImageProvider
                          : null),
                  child:
                      _selectedImage == null && widget.user?.avatarUrl == null
                          ? const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 50,
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: nameController,
                label: 'Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                enabled: !isEdit,
              ), // Email cannot be edited
              const SizedBox(height: 12),
              _buildField(
                controller: countryController,
                label: 'Country',
                icon: Icons.public,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: dobController,
                label: 'Date of Birth',
                icon: Icons.cake,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(isEdit ? 'Update User' : 'Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
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
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
