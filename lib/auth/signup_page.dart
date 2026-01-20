import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../services/database_service.dart';
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

  bool loading = false;
  int waitSeconds = 0;
  Timer? _timer;

  void startCountdown(int seconds) {
    setState(() => waitSeconds = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waitSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => waitSeconds--);
      }
    });
  }

  Future<void> _signUp() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields (Password min 6 chars)')));
      return;
    }

    setState(() => loading = true);
    try {
      final userId = await db.signUp(
        email: emailController.text.trim(), 
        password: passwordController.text.trim(), 
        name: nameController.text.trim()
      );
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfileFormPage(
          afterSignup: true, 
          initialName: nameController.text.trim(),
          initialUserId: userId,
        )),
      );
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit') {
        startCountdown(45);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              _inputField("Name", nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _inputField("Email", emailController, Icons.email_outlined),
              const SizedBox(height: 16),
              _inputField("Password", passwordController, Icons.lock_outline, obscure: true),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (waitSeconds == 0 && !loading) ? _signUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: loading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : Text(waitSeconds > 0 ? 'Wait ${waitSeconds}s' : 'Sign Up', 
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              
              // UPDATED LOGIN TEXT COLOR AND NAVIGATION
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
return TextField(
  controller: controller,
  obscureText: obscure,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
    hintText: label, // stays inside the field
    hintStyle: const TextStyle(color: Colors.grey), 
    prefixIcon: Icon(icon, color: Colors.green),
    filled: true,
    fillColor: Colors.white10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  ),
);



  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}