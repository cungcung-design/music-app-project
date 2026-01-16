import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/toast.dart';
import 'signup_page.dart';
import '../home_page.dart';
import '../admin/pages/admin_home.dart';

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
      // Using a SingleChildScrollView to prevent overflow when keyboard appears
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, color: Colors.green, size: 80),
              const SizedBox(height: 10),
              const Text(
                "Welcome Back",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              _input(emailController, "Email", icon: Icons.email_outlined),
              const SizedBox(height: 16),
              _input(passwordController, "Password",
                  obscure: true, icon: Icons.lock_outline),
              const SizedBox(height: 24),

              _button("LOGIN", () async {
                setState(() => isLoading = true);
                try {
                  await db.login(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                  if (db.currentUser != null) {
                    // Fetch user profile to check role
                    final profile = await db.getProfile(db.currentUser!.id);
                    final role = profile?.role;

                    if (!mounted) return;

                    if (role == 'admin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminHomePage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const UserHomePage()),
                      );
                    }
                  }
                } catch (e) {
                  if (!mounted) return;
                  showToast(context, "Login failed", isError: true);
                }
                if (mounted) setState(() => isLoading = false);
              }),

              const SizedBox(height: 20),

              // Improved Navigation to Signup
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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

  // Updated input with icon support
  Widget _input(TextEditingController c, String h,
      {bool obscure = false, IconData? icon}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: h,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 1),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55, 
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
