import 'package:flutter/material.dart';
import 'package:project/user/pages/complete_profile_page.dart';
import 'package:project/user/pages/profile_form_page.dart';
import 'package:project/user/pages/user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/login_page.dart';
import 'home_page.dart';
import 'admin/pages/admin_home.dart';
import 'services/database_service.dart';
import "user/pages/profile_form_page.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://osuocayynprlqlmbsqop.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdW9jYXl5bnBybHFsbWJzcW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MzI0MzMsImV4cCI6MjA4MzEwODQzM30.92RSKN2IrQveJJ7FCZmR6Vw3uWoWcEadGv1Kp5ZW6Wg',
    debug: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseService db = DatabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Optional delay (safe Supabase init)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;

    // Step 1: Not logged in → show LoginPage
    if (user == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
      );
    }

    // Step 2: Admin user → go to AdminHomePage
    if (user.email == 'admin@example.com') {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AdminHomePage(),
      );
    }

    // Step 3: Normal logged-in user → UserHomePage
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserHomePage(),
    );
  }
}
