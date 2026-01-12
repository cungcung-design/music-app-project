import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/toast.dart';
import '../user/pages/profile_form_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final db = DatabaseService();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _input(nameController, "Name"),
            const SizedBox(height: 16),
            _input(emailController, "Email"),
            const SizedBox(height: 16),
            _input(passwordController, "Password", obscure: true),
            const SizedBox(height: 24),

            _button("SIGN UP", () async {
              setState(() => isLoading = true);
              try {
                await db.signUp(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );
                if (db.currentUser != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileFormPage()),
                  );
                }
              } catch (e) {
                showToast(context, "Signup failed", isError: true);
              }
              setState(() => isLoading = false);
            }),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String h, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: h,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
