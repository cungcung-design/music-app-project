import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';

class UserDetailPage extends StatefulWidget {
  final Profile user;

  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Profile user;
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;

  // Controllers for editing
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController countryController;
  late TextEditingController dobController;

  @override
  void initState() {
    super.initState();
    user = widget.user;

    nameController = TextEditingController(text: user.name);
    emailController = TextEditingController(text: user.email);
    countryController = TextEditingController(text: user.country ?? '');
    dobController = TextEditingController(text: user.dob ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    countryController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
appBar: AppBar(
  title: const Text('User Details'),
  backgroundColor: Colors.black,
  iconTheme: const IconThemeData(color: Colors.white), // 
  actions: [
    IconButton(
      icon: Icon(isEditing ? Icons.cancel : Icons.edit, color: Colors.white),
      onPressed: () {
        setState(() {
          isEditing = !isEditing;
        });
      },
    )
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                backgroundImage:
                    user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            isEditing ? _editForm() : _viewDetails(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// VIEW MODE
  Widget _viewDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile('Name', user.name),
        _infoTile('Email', user.email),
        _infoTile('Country', user.country ?? '—'),
        _infoTile('Date of Birth', user.dob ?? '—'),
        _infoTile('User ID', user.id),
      ],
    );
  }

  /// EDIT MODE
  Widget _editForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _editTile('Name', nameController),
          _editTile('Email', emailController, enabled: false),
          _editTile('Country', countryController),
          _editTile('Date of Birth', dobController),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            onPressed: _saveChanges,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editTile(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Cannot be empty' : null,
      ),
    );
  }

  /// SAVE EDITS
  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final db = DatabaseService();
    try {
      await db.updateProfile(
        userId: user.id,
        name: nameController.text.trim(),
        dob: dobController.text.trim(),
        country: countryController.text.trim(),
      );

      setState(() {
        user = Profile(
          id: user.id,
          email: user.email,
          name: nameController.text.trim(),
          dob: dobController.text.trim(),
          country: countryController.text.trim(),
          avatarUrl: user.avatarUrl,
        );
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// DELETE USER
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this user?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Navigator.pop(context);

              final db = DatabaseService();
              await db.deleteUser(user.id);

              Navigator.pop(context); // go back to user list
            },
          ),
        ],
      ),
    );
  }
}
