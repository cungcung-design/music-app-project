import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/database_seeder.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://osuocayynprlqlmbsqop.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdW9jYXl5bnBybHFsbWJzcW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MzI0MzMsImV4cCI6MjA4MzEwODQzM30.92RSKN2IrQveJJ7FCZmR6Vw3uWoWcEadGv1Kp5ZW6Wg',
  );

  print('Testing database seeder...');
  try {
    await seedDatabase();
    print('Seeder test completed successfully.');
  } catch (e) {
    print('Error during seeding: $e');
  }
}
