import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/toast.dart';
import 'signup_page.dart';
import '../user/user_profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final db = DatabaseService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, color: Colors.green, size: 80),
            const SizedBox(height: 30),

            _input(emailController, "Email"),
            const SizedBox(height: 16),
            _input(passwordController, "Password", obscure: true),
            const SizedBox(height: 24),

            _button("LOGIN", () async {
              setState(() => isLoading = true);
              try {
                await db.login(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );
                if (db.currentUser != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
                  );
                }
              } catch (e) {
                showToast(context, "Login failed", isError: true);
              }
              setState(() => isLoading = false);
            }),

            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(color: Colors.green),
              ),
            ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
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
