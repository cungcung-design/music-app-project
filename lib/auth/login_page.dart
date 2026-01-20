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
              _button("LOGIN", _loginUser),
              const SizedBox(height: 20),
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

  // Login function
  Future<void> _loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validate email
    if (email.isEmpty) {
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
      // Supabase login
      await db.login(email: email, password: password);

      // Wait a bit for session to be established
      await Future.delayed(const Duration(milliseconds: 100));

      final user = db.currentUser;
      if (user == null) {
        if (mounted) {
          showToast(context, "Login failed - please try again", isError: true);
        }
        return;
      }

      // Get profile and role - handle errors gracefully
      String role = 'user';
      try {
        final profile = await db.getProfile(user.id);
        role = profile?.role ?? 'user';
      } catch (e) {
        // If profile fetch fails, continue with default role
        print('Warning: Could not fetch profile: $e');
        role = 'user';
      }

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show more specific error message
      String errorMessage = "Login failed";
      final errorString = e.toString().toLowerCase();
      
      // Extract the actual error message if it's wrapped in Exception
      String actualError = e.toString();
      if (actualError.contains('Exception: ')) {
        actualError = actualError.split('Exception: ').last;
        if (actualError.endsWith(')')) {
          actualError = actualError.substring(0, actualError.length - 1);
        }
      }
      
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid email or password') ||
          errorString.contains('invalid request')) {
        errorMessage = "Invalid email or password";
      } else if (errorString.contains('email not confirmed')) {
        errorMessage = "Please confirm your email before logging in";
      } else if (errorString.contains('too many requests')) {
        errorMessage = "Too many login attempts. Please wait a moment";
      } else if (errorString.contains('user not found')) {
        errorMessage = "No account found with this email";
      } else if (errorString.contains('400') || errorString.contains('bad request')) {
        errorMessage = "Invalid request. Please check your email format.";
      } else {
        // Show actual error for debugging
        print('Login error details: $e');
        errorMessage = actualError.isNotEmpty ? actualError : "Login failed. Please try again.";
      }
      
      showToast(context, errorMessage, isError: true);
    }

    if (mounted) setState(() => isLoading = false);
  }

  // Input field
  Widget _input(TextEditingController controller, String hint,
      {bool obscure = false, IconData? icon}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
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

  // Button widget
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
