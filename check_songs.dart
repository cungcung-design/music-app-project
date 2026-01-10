import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://osuocayynprlqlmbsqop.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdW9jYXl5bnBybHFsbWJzcW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MzI0MzMsImV4cCI6MjA4MzEwODQzM30.92RSKN2IrQveJJ7FCZmR6Vw3uWoWcEadGv1Kp5ZW6Wg',
  );

  print('Checking songs in database...');
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('songs').select().order('name');

    if (response.isEmpty) {
      print('No songs found in database.');
    } else {
      print('Found ${response.length} songs:');
      for (var song in response) {
        print(
          '- ${song['name']} (ID: ${song['id']}, Artist ID: ${song['artist_id']}, Album ID: ${song['album_id']}, Audio URL: ${song['audio_url']})',
        );
      }
    }
  } catch (e) {
    print('Error checking songs: $e');
  }
}
