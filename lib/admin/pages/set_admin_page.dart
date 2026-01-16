import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class SetAdminPage extends StatefulWidget {
  const SetAdminPage({super.key});

  @override
  State<SetAdminPage> createState() => _SetAdminPageState();
}

class _SetAdminPageState extends State<SetAdminPage> {
  final DatabaseService db = DatabaseService();
  final emailController = TextEditingController(text: 'admin@gmail.com');
  bool isLoading = false;

  Future<void> _setAdminRole() async {
    setState(() => isLoading = true);
    try {
      // First, find the user by email
      final users = await db.supabase
          .from('profiles')
          .select('id')
          .eq('email', emailController.text.trim())
          .maybeSingle();

      if (users == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final userId = users['id'] as String;
      await db.updateUserRole(userId, 'admin');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin role set successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            const Text('Set Admin Role', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _setAdminRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.black,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Set Admin Role'),
            ),
          ],
        ),
      ),
    );
  }
}
