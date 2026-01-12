import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/profile.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid uuid = const Uuid();

  // -------------------- Helper --------------------
  String? getStorageUrl(String? path, String bucket) {
    if (path == null || path.isEmpty) return null;
    final url = path.startsWith('http')
        ? path
        : supabase.storage.from(bucket).getPublicUrl(path);
    if (url.contains('your_supabase_url')) return null;
    return url;
  }

  String? resolveUrl({
    required SupabaseClient supabase,
    required String bucket,
    String? value,
  }) {
    if (value == null || value.isEmpty) return null;

    // already a full URL
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // storage path
    return supabase.storage.from(bucket).getPublicUrl(value);
  }

  static String? resolveImageUrl(String? value, String bucket) {
    if (value == null || value.isEmpty) return null;

    // Case 1: Already a full URL
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Case 2: Storage path → convert to public URL
    return Supabase.instance.client.storage.from(bucket).getPublicUrl(value);
  }

  // -------------------- AUTH --------------------
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await createProfileIfNotExists(res.user!.id, email, name);
    } else if (res.session == null) {
      throw Exception('Signup failed');
    }
  }

  Future<void> login({required String email, required String password}) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Login failed');
  }

  Future<void> logout() async => supabase.auth.signOut();

  // -------------------- PROFILE --------------------
  Future<Profile?> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data != null
        ? Profile.fromMap(data as Map<String, dynamic>, supabase: supabase)
        : null;
  }

  // -------------------------------
  // GET CURRENT USER PROFILE
  // -------------------------------
  Future<Profile?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  // -------------------------------
  // UPDATE PROFILE
  // -------------------------------
  Future<void> updateProfile({
    required String userId,
    required String name,
    String? dob,
    String? country,
    String? avatarPath,
  }) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      if (dob != null) 'dob': dob,
      if (country != null) 'country': country,
      if (avatarPath != null) 'avatar_url': avatarPath,
    });
  }

  // -------------------------------
  // UPLOAD AVATAR (OPTIONAL)
  // -------------------------------
  Future<String> uploadAvatar(File file, String userId) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'user_avatars/$userId/$fileName';

    await supabase.storage
        .from('profiles')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return path; // store path in avatar_url column
  }

  // -------------------------------
  // CREATE PROFILE IF NOT EXISTS
  // -------------------------------
  Future<void> createProfileIfNotExists(
    String userId,
    String email,
    String name,
  ) async {
    final existing = await getProfile(userId);
    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'name': name,
      });
    }
  }

  // -------------------------------
  // GET ALL USERS
  // -------------------------------
  Future<List<Profile>> getAllUsers() async {
    final data = await supabase.from('profiles').select().order('name');

    return data
        .map(
          (e) => Profile.fromMap(e as Map<String, dynamic>, supabase: supabase),
        )
        .toList();
  }

  // -------------------------------
  // ADD USER
  // -------------------------------
  Future<void> addUser({
    required String name,
    required String email,
    String? country,
  }) async {
    final id = const Uuid().v4();

    await supabase.from('profiles').insert({
      'id': id,
      'name': name,
      'email': email,
      if (country != null) 'country': country,
    });
  }

  // -------------------------------
  // DELETE USER
  // -------------------------------
  Future<void> deleteUser(String userId) async {
    await supabase.from('profiles').delete().eq('id', userId);
  }

  // ===================== ARTISTS =====================
  Future<List<Artist>> getArtists() async {
    final data = await supabase.from('artists').select();
    final artists = List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Artist.fromMap(e, supabase: supabase)).toList();
    return artists;
  }

  Future<void> addArtist({
    required String name,
    String? bio,
    String? about,
    Uint8List? imageBytes,
    String? contentType,
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      final path =
          'artist_${DateTime.now().millisecondsSinceEpoch}.${contentType == 'image/jpeg' ? 'jpg' : 'png'}';
      await supabase.storage
          .from('artist_profiles')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType ?? 'image/png',
            ),
          );
      imageUrl = supabase.storage.from('artist_profiles').getPublicUrl(path);
    }

    await supabase.from('artists').insert({
      'id': uuid.v4(),
      'name': name,
      'bio': bio ?? '',
      'about': about,
      'artist_url': imageUrl,
    });
  }

  Future<void> updateArtist({
    required String artistId,
    String? name,
    String? bio,
    String? about,
    Uint8List? newImageBytes,
    String? contentType,
  }) async {
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (bio != null) updateData['bio'] = bio;
    if (about != null) updateData['about'] = about;

    if (newImageBytes != null) {
      final path =
          'artist_${DateTime.now().millisecondsSinceEpoch}.${contentType == 'image/jpeg' ? 'jpg' : 'png'}';
      await supabase.storage
          .from('artist_profiles')
          .uploadBinary(
            path,
            newImageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType ?? 'image/png',
            ),
          );
      updateData['artist_url'] = supabase.storage
          .from('artist_profiles')
          .getPublicUrl(path);
    }

    await supabase.from('artists').update(updateData).eq('id', artistId);
  }

  Future<void> deleteArtist(String artistId) async {
    final res = await supabase
        .from('artists')
        .select('artist_url')
        .eq('id', artistId)
        .maybeSingle();
    if (res != null && res['artist_url'] != null) {
      await supabase.storage.from('artist_profiles').remove([
        res['artist_url'],
      ]);
    }
    await supabase.from('artists').delete().eq('id', artistId);
  }

  // ===================== ALBUMS =====================
  Future<List<Album>> getAlbums() async {
    final data = await supabase.from('albums').select();
    final albums = List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Album.fromMap(e, supabase: supabase)).toList();
    return albums;
  }

  Future<void> addAlbum({
    required String name,
    required String artistId,
    File? coverFile, // mobile
    Uint8List? coverBytes, // web
  }) async {
    String? albumPath;

    if (coverFile != null) {
      // Mobile
      final fileName = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      albumPath = 'albums/$fileName';
      await supabase.storage
          .from('album_covers')
          .upload(
            albumPath,
            coverFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );
    } else if (coverBytes != null) {
      // Web
      final fileName = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      albumPath = 'albums/$fileName';
      await supabase.storage
          .from('album_covers')
          .uploadBinary(
            albumPath,
            coverBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );
    }

    await supabase.from('albums').insert({
      'id': uuid.v4(),
      'name': name,
      'artist_id': artistId,
      'album_url': albumPath,
    });
  }

  Future<void> updateAlbum({
    required String albumId,
    String? name,
    String? artistId,
    File? newCoverFile,
    Uint8List? newCoverBytes,
    bool removeCurrentCover = false,
  }) async {
    final Map<String, dynamic> updateData = {};

    if (name != null) updateData['name'] = name;
    if (artistId != null) updateData['artist_id'] = artistId;

    // Handle cover removal or update
    if (removeCurrentCover) {
      // Delete existing cover file if it exists
      final res = await supabase
          .from('albums')
          .select('album_url')
          .eq('id', albumId)
          .maybeSingle();
      final currentPath = res?['album_url'];
      if (currentPath != null && !currentPath.startsWith('http')) {
        await supabase.storage.from('album_covers').remove([currentPath]);
      }
      updateData['album_url'] = null;
    } else if (newCoverFile != null) {
      // Delete existing cover file before uploading new one
      final res = await supabase
          .from('albums')
          .select('album_url')
          .eq('id', albumId)
          .maybeSingle();
      final currentPath = res?['album_url'];
      if (currentPath != null && !currentPath.startsWith('http')) {
        await supabase.storage.from('album_covers').remove([currentPath]);
      }

      final fileName = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'albums/$fileName';

      await supabase.storage
          .from('album_covers')
          .upload(
            path,
            newCoverFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      updateData['album_url'] = path; // ✅ PATH ONLY
    } else if (newCoverBytes != null) {
      // Delete existing cover file before uploading new one
      final res = await supabase
          .from('albums')
          .select('album_url')
          .eq('id', albumId)
          .maybeSingle();
      final currentPath = res?['album_url'];
      if (currentPath != null && !currentPath.startsWith('http')) {
        await supabase.storage.from('album_covers').remove([currentPath]);
      }

      final fileName = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'albums/$fileName';

      await supabase.storage
          .from('album_covers')
          .uploadBinary(
            path,
            newCoverBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      updateData['album_url'] = path; // ✅ PATH ONLY
    }

    await supabase.from('albums').update(updateData).eq('id', albumId);
  }

  Future<void> deleteAlbum(String albumId) async {
    final res = await supabase
        .from('albums')
        .select('album_url')
        .eq('id', albumId)
        .maybeSingle();

    final path = res?['album_url'];

    if (path != null && !path.startsWith('http')) {
      await supabase.storage.from('album_covers').remove([path]);
    }

    await supabase.from('albums').delete().eq('id', albumId);
  }

  // ===================== SONGS =====================
  Future<List<Song>> getSongs() async {
    final res = await supabase.from('songs').select();
    final data = List<Map<String, dynamic>>.from(res);
    return data
        .map(
          (e) => Song.fromMap(
            e,
            storageUrl: resolveUrl(
              supabase: supabase,
              bucket: 'song_audio',
              value: e['audio_url'],
            ),
          ),
        )
        .toList();
  }

  Future<List<Song>> getSongsWithDetails() async {
    final res = await supabase.from('songs').select();
    final data = List<Map<String, dynamic>>.from(res);
    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );
    return data.map((e) {
      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );
      final albumId = e['album_id']?.toString() ?? '';
      final albumImage = albumId.isNotEmpty ? albumMap[albumId] : null;
      final artistId = e['artist_id']?.toString();
      final artistName = artistId != null ? artistMap[artistId] : null;
      return Song(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: artistId ?? '',
        albumId: albumId,
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  Future<List<Song>> getSongsByArtist(String artistId) async {
    final res = await supabase.from('songs').select().eq('artist_id', artistId);
    final data = List<Map<String, dynamic>>.from(res);
    return data
        .map(
          (e) => Song.fromMap(
            e,
            storageUrl: resolveUrl(
              supabase: supabase,
              bucket: 'song_audio',
              value: e['audio_url'],
            ),
          ),
        )
        .toList();
  }

  Future<List<Song>> getSongsByAlbum(String albumId) async {
    final res = await supabase.from('songs').select().eq('album_id', albumId);
    final data = List<Map<String, dynamic>>.from(res);
    return data
        .map(
          (e) => Song.fromMap(
            e,
            storageUrl: resolveUrl(
              supabase: supabase,
              bucket: 'song_audio',
              value: e['audio_url'],
            ),
          ),
        )
        .toList();
  }

  Future<String> uploadSongAudio(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    await supabase.storage
        .from('song_audio')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('song_audio').getPublicUrl(fileName);
  }

  Future<void> addSong({
    required String name,
    required String artistId,
    required String albumId,
    required String audioUrl,
  }) async {
    await supabase.from('songs').insert({
      'id': uuid.v4(),
      'name': name,
      'artist_id': artistId,
      'album_id': albumId,
      'audio_url': audioUrl,
    });
  }

  Future<void> updateSong({
    required String id,
    String? name,
    String? artistId,
    String? albumId,
    String? audioUrl,
  }) async {
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (artistId != null) updateData['artist_id'] = artistId;
    if (albumId != null) updateData['album_id'] = albumId;
    if (audioUrl != null) updateData['audio_url'] = audioUrl;

    await supabase.from('songs').update(updateData).eq('id', id);
  }

  Future<void> deleteSong(String id) async {
    final res = await supabase
        .from('songs')
        .select('audio_url')
        .eq('id', id)
        .maybeSingle();
    if (res != null && res['audio_url'] != null) {
      await supabase.storage.from('song_audio').remove([res['audio_url']]);
    }
    await supabase.from('songs').delete().eq('id', id);
  }

  // -------------------- FAVORITES --------------------
  Future<void> addToFavorites(String songId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    await supabase.from('user_favorites').insert({
      'id': uuid.v4(),
      'user_id': user.id,
      'song_id': songId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromFavorites(String songId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    await supabase
        .from('user_favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('song_id', songId);
  }

  Future<bool> isFavorite(String songId) async {
    final user = currentUser;
    if (user == null) return false;
    final res = await supabase
        .from('user_favorites')
        .select()
        .eq('user_id', user.id)
        .eq('song_id', songId)
        .maybeSingle();
    return res != null;
  }

  Future<List<Song>> getFavorites() async {
    final user = currentUser;
    if (user == null) return [];
    final res = await supabase
        .from('user_favorites')
        .select('song_id')
        .eq('user_id', user.id);
    final songIds = List<String>.from(res.map((e) => e['song_id']));
    if (songIds.isEmpty) return [];
    final songsRes = await supabase
        .from('songs')
        .select()
        .filter('id', 'in', '(${songIds.join(',')})');
    final data = List<Map<String, dynamic>>.from(songsRes);
    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );
    return data.map((e) {
      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );
      final albumId = e['album_id']?.toString() ?? '';
      final albumImage = albumId.isNotEmpty ? albumMap[albumId] : null;
      final artistId = e['artist_id']?.toString();
      final artistName = artistId != null ? artistMap[artistId] : null;
      return Song(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: artistId ?? '',
        albumId: albumId,
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  // -------------------- SEARCH --------------------
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    final res = await supabase
        .from('songs')
        .select()
        .ilike('name', '%$query%')
        .order('name');
    final data = List<Map<String, dynamic>>.from(res);
    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );
    return data.map((e) {
      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );
      final albumId = e['album_id']?.toString() ?? '';
      final albumImage = albumId.isNotEmpty ? albumMap[albumId] : null;
      final artistId = e['artist_id']?.toString();
      final artistName = artistId != null ? artistMap[artistId] : null;
      return Song(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: artistId ?? '',
        albumId: albumId,
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  // -------------------- RECOMMENDED --------------------
  Future<List<Song>> getRecommendedSongs(
    String userId, {
    int limit = 10,
  }) async {
    // Simple recommendation: songs not in favorites, ordered by play count
    final favoritesRes = await supabase
        .from('user_favorites')
        .select('song_id')
        .eq('user_id', userId);
    final favoriteSongIds = List<String>.from(
      favoritesRes.map((e) => e['song_id']),
    );
    final songsRes = await supabase
        .from('songs')
        .select()
        .order('play_count', ascending: false)
        .limit(limit * 2);
    final data = List<Map<String, dynamic>>.from(songsRes);
    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );
    final recommended = data
        .where((e) => !favoriteSongIds.contains(e['id']))
        .take(limit)
        .toList();
    return recommended.map((e) {
      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );
      final albumId = e['album_id']?.toString() ?? '';
      final albumImage = albumId.isNotEmpty ? albumMap[albumId] : null;
      final artistId = e['artist_id']?.toString();
      final artistName = artistId != null ? artistMap[artistId] : null;
      return Song(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: artistId ?? '',
        albumId: albumId,
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  // -------------------- Helper: Album Map --------------------
  Future<Map<String, String>> getAlbumCoverMap() async {
    final albums = await getAlbums();
    return {for (var album in albums) album.id: album.albumProfileUrl ?? ''};
  }

  // Get albums by artist
  Future<List<Album>> getAlbumsByArtist(String artistId) async {
    final data = await supabase
        .from('albums')
        .select()
        .eq('artist_id', artistId);
    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Album.fromMap(e, supabase: supabase)).toList();
  }

  // List files in a storage bucket
  Future<List<String>> listBucketFiles(String bucketName) async {
    final files = await supabase.storage.from(bucketName).list();
    return files.map((file) => file.name).toList();
  }

  // Download image from storage bucket
  Future<Uint8List> downloadImage(String bucket, String path) async {
    return await supabase.storage.from(bucket).download(path);
  }

  // Get orphaned songs from storage (files in song_audios bucket not in songs table)
  Future<List<String>> getOrphanedSongs() async {
    final bucketFiles = await listBucketFiles('song_audio');
    final songsRes = await supabase.from('songs').select('audio_url');
    final audioUrls = List<String>.from(
      songsRes.map((e) => e['audio_url'] as String),
    );

    // Extract filenames from URLs (assuming URL format: .../song_audios/filename)
    final referencedFiles = audioUrls
        .map((url) {
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          final songAudiosIndex = pathSegments.indexOf('song_audio');
          if (songAudiosIndex != -1 &&
              songAudiosIndex < pathSegments.length - 1) {
            return pathSegments[songAudiosIndex + 1];
          }
          return '';
        })
        .where((filename) => filename.isNotEmpty)
        .toSet();

    return bucketFiles
        .where((file) => !referencedFiles.contains(file))
        .toList();
  }

  // Add orphaned songs to the table using default artist and album
  Future<void> addOrphanedSongsToTable() async {
    final orphanedFiles = await getOrphanedSongs();
    if (orphanedFiles.isEmpty) return;

    // Ensure "Unknown Artist" exists
    var unknownArtistRes = await supabase
        .from('artists')
        .select('id')
        .eq('name', 'Unknown Artist')
        .maybeSingle();
    String unknownArtistId;
    if (unknownArtistRes == null) {
      unknownArtistId = uuid.v4();
      await supabase.from('artists').insert({
        'id': unknownArtistId,
        'name': 'Unknown Artist',
        'bio': '',
        'about': '',
        'artist_url': null,
      });
    } else {
      unknownArtistId = unknownArtistRes['id'];
    }

    // Ensure "Unknown Album" exists for the unknown artist
    var unknownAlbumRes = await supabase
        .from('albums')
        .select('id')
        .eq('name', 'Unknown Album')
        .eq('artist_id', unknownArtistId)
        .maybeSingle();
    String unknownAlbumId;
    if (unknownAlbumRes == null) {
      unknownAlbumId = uuid.v4();
      await supabase.from('albums').insert({
        'id': unknownAlbumId,
        'name': 'Unknown Album',
        'artist_id': unknownArtistId,
        'album_url': null,
      });
    } else {
      unknownAlbumId = unknownAlbumRes['id'];
    }

    // Add each orphaned song
    for (final file in orphanedFiles) {
      final songId = uuid.v4();
      // Use filename as song name (remove extension if present)
      final name = file.contains('.')
          ? file.substring(0, file.lastIndexOf('.'))
          : file;
      await supabase.from('songs').insert({
        'id': songId,
        'name': name,
        'artist_id': unknownArtistId,
        'album_id': unknownAlbumId,
        'audio_url': file, // store as path
      });
    }
  }

  // Fetch all songs from bucket storage, including orphaned ones
  Future<List<Song>> getAllSongsFromBucket() async {
    final bucketFiles = await listBucketFiles('song_audio');
    final dbSongs = await getSongsWithDetails();

    // Create a map of filename to Song for quick lookup
    final songMap = <String, Song>{};
    for (final song in dbSongs) {
      if (song.audioUrl != null) {
        final uri = Uri.parse(song.audioUrl!);
        final pathSegments = uri.pathSegments;
        final songAudiosIndex = pathSegments.indexOf('song_audio');
        if (songAudiosIndex != -1 &&
            songAudiosIndex < pathSegments.length - 1) {
          final filename = pathSegments[songAudiosIndex + 1];
          songMap[filename] = song;
        }
      }
    }

    final allSongs = <Song>[];
    for (final file in bucketFiles) {
      if (songMap.containsKey(file)) {
        allSongs.add(songMap[file]!);
      } else {
        // Orphaned song: create Song object with default metadata
        final name = file.contains('.')
            ? file.substring(0, file.lastIndexOf('.'))
            : file;
        final audioUrl = supabase.storage.from('song_audio').getPublicUrl(file);
        allSongs.add(
          Song(
            id: '', // No ID for orphaned
            name: name,
            artistId: '',
            albumId: '',
            audioUrl: audioUrl,
            artistName: 'Unknown Artist',
            albumImage: null,
            playCount: null,
          ),
        );
      }
    }

    return allSongs;
  }

  // Fetch all albums from bucket storage, including orphaned ones
  Future<List<Album>> getAllAlbumsFromBucket() async {
    final bucketFiles = await listBucketFiles('album_covers');
    final dbAlbums = await getAlbums();

    // Create a map of filename to Album for quick lookup
    final albumMap = <String, Album>{};
    for (final album in dbAlbums) {
      if (album.albumProfileUrl != null) {
        final uri = Uri.parse(album.albumProfileUrl!);
        final pathSegments = uri.pathSegments;
        final albumCoversIndex = pathSegments.indexOf('album_covers');
        if (albumCoversIndex != -1 &&
            albumCoversIndex < pathSegments.length - 1) {
          final filename = pathSegments[albumCoversIndex + 1];
          albumMap[filename] = album;
        }
      }
    }

    final allAlbums = <Album>[];
    for (final file in bucketFiles) {
      if (albumMap.containsKey(file)) {
        allAlbums.add(albumMap[file]!);
      } else {
        // Orphaned album: create Album object with default metadata
        final name = file.contains('.')
            ? file.substring(0, file.lastIndexOf('.'))
            : file;
        final albumUrl = supabase.storage
            .from('album_covers')
            .getPublicUrl(file);
        allAlbums.add(
          Album(
            id: '', // No ID for orphaned
            name: name,
            artistId: '',
            albumProfileUrl: albumUrl,
          ),
        );
      }
    }

    return allAlbums;
  }

  // Fetch all artists from bucket storage, including orphaned ones
  Future<List<Artist>> getAllArtistsFromBucket() async {
    final bucketFiles = await listBucketFiles('artist_profiles');
    final dbArtists = await getArtists();

    // Create a map of filename to Artist for quick lookup
    final artistMap = <String, Artist>{};
    for (final artist in dbArtists) {
      if (artist.artistProfileUrl != null) {
        final uri = Uri.parse(artist.artistProfileUrl!);
        final pathSegments = uri.pathSegments;
        final artistProfilesIndex = pathSegments.indexOf('artist_profiles');
        if (artistProfilesIndex != -1 &&
            artistProfilesIndex < pathSegments.length - 1) {
          final filename = pathSegments[artistProfilesIndex + 1];
          artistMap[filename] = artist;
        }
      }
    }

    final allArtists = <Artist>[];
    for (final file in bucketFiles) {
      if (artistMap.containsKey(file)) {
        allArtists.add(artistMap[file]!);
      } else {
        // Orphaned artist: create Artist object with default metadata
        final name = file.contains('.')
            ? file.substring(0, file.lastIndexOf('.'))
            : file;
        final artistUrl = supabase.storage
            .from('artist_profiles')
            .getPublicUrl(file);
        allArtists.add(
          Artist(
            id: '', // No ID for orphaned
            name: name,
            bio: '',
            about: '',
            artistProfileUrl: artistUrl,
          ),
        );
      }
    }

    return allArtists;
  }
}
