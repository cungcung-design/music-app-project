import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './home_page.dart';

import 'admin/pages/admin_home.dart';
import 'services/database_service.dart';

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
          body: Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
        ),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserHomePage(), // ✅ DIRECT ADMIN ACCESS
    );
  }
}
