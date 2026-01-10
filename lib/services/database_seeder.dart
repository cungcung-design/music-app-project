import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

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

  // ===================== 1️⃣ SEED ARTISTS =====================
  print('Step 1: Syncing Artists...');
  final artistFiles = await supabase.storage.from('artist_profiles').list();
  print('Found ${artistFiles.length} files in artist_profiles bucket');

  for (final file in artistFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    // Check if artist already exists
    final exists = await supabase
        .from('artists')
        .select()
        .eq('artist_url', file.name);

    if ((exists as List).isEmpty) {
      final artistName = file.name.split('.').first.replaceAll('_', ' ');
      print('Adding new artist: $artistName');

      await db.addArtist(
        name: artistName,
        bio: 'Bio for $artistName',
        artistProfilePath: file.name,
      );
    }
  }

  final artists = await db.getArtists();
  if (artists.isEmpty) {
    throw Exception(
      'Artists table is empty after seeding. Check database permissions.',
    );
  }

  // ===================== 2️⃣ SEED ALBUMS =====================
  print('Step 2: Syncing Albums...');
  final albumFiles = await supabase.storage.from('album_covers').list();

  for (final file in albumFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    final exists = await supabase
        .from('albums')
        .select()
        .eq('album_url', file.name);

    if ((exists as List).isEmpty) {
      final randomArtistId = artists[random.nextInt(artists.length)].id;
      final albumName = file.name.split('.').first.replaceAll('_', ' ');

      await db.addAlbum(
        name: albumName,
        artistId: randomArtistId,
      
        albumProfilePath: file.name,
      );

      print('Inserted album: $albumName');
    }
  }

  final albums = await db.getAlbums();
  if (albums.isEmpty) print('No albums found for songs seeding.');

  // ===================== 3️⃣ SEED SONGS =====================
  print('Step 3: Syncing Songs...');
  final songFiles = await supabase.storage.from('song_audio').list();

  for (final file in songFiles) {
    if (file.name == '.emptyFolderPlaceholder') continue;

    final exists = await supabase
        .from('songs')
        .select()
        .eq('audio_url', file.name);

    if ((exists as List).isEmpty && albums.isNotEmpty) {
      final randomAlbum = albums[random.nextInt(albums.length)];
      final songName = file.name.split('.').first.replaceAll('_', ' ');

      await db.addSong(
        name: songName,
        artistId: randomAlbum.artistId,
        albumId: randomAlbum.id,
        audioUrl: file.name,
      );

      print('Inserted song: $songName');
    }
  }

  print('--- Database Seeding Completed Successfully ---');
}
