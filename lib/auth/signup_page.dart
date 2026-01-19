import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/toast.dart';
import '../user/pages/profile_form_page.dart';
import 'login_page.dart';

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
  bool isAdmin = false;

  // Email validation regex
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // Signup function with validation
  Future<void> _signUpUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validate name
    if (name.isEmpty) {
      showToast(context, "Please enter your full name", isError: true);
      return;
    }

    // Validate email
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      showToast(context, "Please enter a valid email address", isError: true);
      return;
    }

    // Validate password
    if (password.isEmpty || password.length < 6) {
      showToast(context, "Password must be at least 6 characters",
          isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      await db.signUp(
        name: name,
        email: email,
        password: password,
        role: isAdmin ? 'admin' : 'user',
      );
      if (!mounted) return;
      showToast(context, "Signup successful!", isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileFormPage(afterSignup: true, initialName: name),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context, "Signup failed: ${e.toString()}", isError: true);
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.music_note, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _input(nameController, "Full Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _input(emailController, "Email", icon: Icons.email_outlined),
              const SizedBox(height: 16),
              _input(passwordController, "Password",
                  obscure: true, icon: Icons.lock_outline),
              const SizedBox(height: 32),
              _button("SIGN UP", _signUpUser),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Login",
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
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
