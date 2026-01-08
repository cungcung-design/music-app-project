import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final supabase = Supabase.instance.client;
final uuid = Uuid();

Future<void> seedDatabase() async {
  // ---------------- ARTISTS ----------------
  final artistFiles = await supabase.storage.from('artist_profiles').list();
  for (final file in artistFiles) {
    final id = uuid.v4();
    final name = file.name.split('_').first; // optional: derive name from filename
    final path = 'artist_profiles/${file.name}';

    // Check if artist already exists
    final exists = await supabase.from('artists').select().eq('profile_url', path);
    if ((exists as List).isEmpty) {
      await supabase.from('artists').insert({
        'id': id,
        'name': name,
        'bio': 'Bio for $name',
        'profile_url': path,
      });
      print('Inserted artist: $name');
    }
  }

  // ---------------- ALBUMS ----------------
  final albumFiles = await supabase.storage.from('album_covers').list();
  for (final file in albumFiles) {
    final id = uuid.v4();
    final name = file.name.split('_').first;
    final path = 'album_covers/${file.name}';

    // Pick a random artist for demo
    final artists = await supabase.from('artists').select();
    if ((artists as List).isEmpty) continue;
    final artistId = artists.first['id'];

    // Check if album exists
    final exists = await supabase.from('albums').select().eq('cover_url', path);
    if ((exists as List).isEmpty) {
      await supabase.from('albums').insert({
        'id': id,
        'name': name,
        'artist_id': artistId,
        'cover_url': path,
      });
      print('Inserted album: $name');
    }
  }

  // ---------------- SONGS ----------------
  final songFiles = await supabase.storage.from('song_audio').list();
  for (final file in songFiles) {
    final id = uuid.v4();
    final name = file.name.split('_').first;
    final path = 'song_audio/${file.name}';

    // Pick a random album for demo
    final albums = await supabase.from('albums').select();
    if ((albums as List).isEmpty) continue;
    final albumId = albums.first['id'];

    // Pick artist from album
    final album = await supabase.from('albums').select().eq('id', albumId).maybeSingle();
    final artistId = album!['artist_id'];

    // Check if song exists
    final exists = await supabase.from('songs').select().eq('audio_url', path);
    if ((exists as List).isEmpty) {
      await supabase.from('songs').insert({
        'id': id,
        'name': name,
        'artist_id': artistId,
        'album_id': albumId,
        'audio_url': path,
      });
      print('Inserted song: $name');
    }
  }

  print('Seeding finished!');
}
