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

  print('Fetching orphaned songs from storage...');
  try {
    final orphanedSongs = await dbService.getOrphanedSongs();
    print('Found ${orphanedSongs.length} orphaned songs:');
    for (var song in orphanedSongs) {
      print('- $song');
    }

    if (orphanedSongs.isNotEmpty) {
      print('\nAdding orphaned songs to the database...');
      await dbService.addOrphanedSongsToTable();
      print('Orphaned songs added successfully.');
    } else {
      print('No orphaned songs to add.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
