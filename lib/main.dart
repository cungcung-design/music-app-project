import 'package:flutter/material.dart';
import "package:supabase_flutter/supabase_flutter.dart";
import 'auth/login_page.dart';
import "admin/pages/admin_home.dart";
import"home_page.dart";

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminHomePage()    
      );
  }
}
