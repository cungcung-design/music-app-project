import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  try {
    await Supabase.initialize(
      url: 'https://osuocayynprlqlmbsqop.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdW9jYXl5bnBybHFsbWJzcW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MzI0MzMsImV4cCI6MjA4MzEwODQzM30.92RSKN2IrQveJJ7FCZmR6Vw3uWoWcEadGv1Kp5ZW6Wg',
      debug: true,
    );

    print('Supabase initialized successfully');

    // Test basic connection
    final client = Supabase.instance.client;
    print('Client created: ${client != null}');

    // Try to get current user (should be null since not logged in)
    final user = client.auth.currentUser;
    print('Current user: $user');

    // Test a simple query to check if database is accessible
    try {
      final response = await client.from('profiles').select('count').limit(1);
      print(
          'Database connection test successful: ${response.length} records found');
    } catch (e) {
      print('Database connection test failed: $e');
    }
  } catch (e) {
    print('Supabase initialization failed: $e');
  }
}
