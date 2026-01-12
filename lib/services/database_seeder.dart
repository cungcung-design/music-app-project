import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';

final db = DatabaseService();
final random = Random();
final uuid = const Uuid();

Future<void> seedDatabase() async {
  final supabase = Supabase.instance.client;
  print('--- Database Seeding Started ---');


  // ---------------- 1️⃣ SEED ARTISTS ----------------
  print('Step 1: Seeding Artists...');
  final artistFiles = await supabase.storage.from('artist_profiles').list();
  final List<Artist> artists = [];

  for (final file in artistFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    final artistName = file.name.split('.').first.replaceAll('_', ' ');
    print('Adding artist: $artistName');

    await supabase.from('artists').insert({
      'name': artistName,
      'bio': 'Bio for $artistName',
      'artist_url': file.name,
    });

    // Get the generated id
    final inserted = await supabase
        .from('artists')
        .select('id')
        .eq('name', artistName)
        .single();
    final artistId = inserted['id'] as String;

    // Store locally for album assignment
    artists.add(
      Artist(
        id: artistId,
        name: artistName,
        bio: 'Bio for $artistName',
        artistProfileUrl: file.name,
      ),
    );
  }

  if (artists.isEmpty) {
    throw Exception('No artists found in bucket or database.');
  }

  // ---------------- 2️⃣ SEED ALBUMS ----------------
  print('Step 2: Seeding Albums...');
  final albumFiles = await supabase.storage.from('album_covers').list();
  final List<Album> albums = [];

  for (final file in albumFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    final albumName = file.name.split('.').first.replaceAll('_', ' ');
    final randomArtist =
        artists[random.nextInt(artists.length)]; // Pick random artist

    await supabase.from('albums').insert({
      'name': albumName,
      'artist_id': randomArtist.id, // UUID string
      'album_url': file.name,
    });

    // Get the generated id
    final inserted = await supabase
        .from('albums')
        .select('id')
        .eq('name', albumName)
        .single();
    final albumId = inserted['id'] as String;

    albums.add(
      Album(
        id: albumId,
        name: albumName,
        artistId: randomArtist.id,
        albumProfilePath: file.name,
      ),
    );
    print('Inserted album: $albumName for artist: ${randomArtist.name}');
  }

  if (albums.isEmpty) {
    print('No albums found, skipping songs seeding.');
    return;
  }

  // ---------------- 3️⃣ SEED SONGS ----------------
  print('Step 3: Seeding Songs...');
  final songFiles = await supabase.storage.from('song_audio').list();

  for (final file in songFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    final songName = file.name.split('.').first.replaceAll('_', ' ');
    final randomAlbum =
        albums[random.nextInt(albums.length)]; // Pick random album

    await db.addSong(
      name: songName,
      artistId: randomAlbum.artistId, // UUID string
      albumId: randomAlbum.id,
      audioUrl: file.name,
    );

    print('Inserted song: $songName into album: ${randomAlbum.name}');
  }

  print('--- Database Seeding Completed Successfully ---');
}
