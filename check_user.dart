import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/database_service.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://osuocayynprlqlmbsqop.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdW9jYXl5bnBybHFsbWJzcW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MzI0MzMsImV4cCI6MjA4MzEwODQzM30.92RSKN2IrQveJJ7FCZmR6Vw3uWoWcEadGv1Kp5ZW6Wg',
  );

  final dbService = DatabaseService();

  print('Checking database user...');

  try {
    // Check if user is logged in
    final currentUser = dbService.currentUser;
    if (currentUser != null) {
      print('Current user: ${currentUser.email} (ID: ${currentUser.id})');

      // Get user profile
      final profile = await dbService.getUserProfile();
      if (profile != null) {
        print('Profile: ${profile.name}, Email: ${profile.email}');
      } else {
        print('No profile found for current user.');
      }
    } else {
      print('No user is currently logged in.');
    }

    // Check database connection by fetching users
    print('\nTesting database connection...');
    final users = await dbService.getAllUsers();
    print('Successfully connected to database. Found ${users.length} users.');
  } catch (e) {
    print('Error: $e');
  }
}
