import 'dart:io';
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
    return path.startsWith('http')
        ? path
        : supabase.storage.from(bucket).getPublicUrl(path);
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
      await _createProfileIfNotExists(res.user!.id, email, name);
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
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res != null ? Profile.fromMap(res) : null;
  }

  Future<Profile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
    required String dob,
    required String country,
    String? avatarUrl,
  }) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      'dob': dob,
      'country': country,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'user_avatars/$userId/$fileName';
    await supabase.storage
        .from('profiles')
        .uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return supabase.storage.from('profiles').getPublicUrl(path);
  }

  Future<void> _createProfileIfNotExists(
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

  Future<List<Profile>> getAllUsers() async {
    final res = await supabase.from('profiles').select().order('name');
    final data = List<Map<String, dynamic>>.from(res);
    return data.map((e) => Profile.fromMap(e)).toList();
  }

  Future<void> deleteUser(String userId) async {
    final res = await supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (res != null && res['avatar_url'] != null) {
      await supabase.storage.from('profiles').remove([res['avatar_url']]);
    }
    await supabase.from('profiles').delete().eq('id', userId);
  }

  // -------------------- ARTISTS --------------------
  Future<List<Artist>> getArtists() async {
    final res = await supabase.from('artists').select().order('name');
    final data = List<Map<String, dynamic>>.from(res);

    return data.map((e) {
      final artistPath = e['artist_url'] as String?;
      return Artist(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        bio: e['bio'] ?? '',
        about: e['about'],
        artistProfilePath: artistPath,
        artistProfileUrl: getStorageUrl(artistPath, 'artist_profiles'),
      );
    }).toList();
  }

  // -------------------- ARTISTS --------------------

  Future<void> updateArtist({
    required String id,
    required String name,
    required String bio,
    required String artistProfilePath, // this is the storage path
    String? about,
  }) async {
    // If there is an old image, you can remove it (optional)
    final oldArtist = await supabase
        .from('artists')
        .select('artist_url')
        .eq('id', id)
        .maybeSingle();

    if (oldArtist != null && oldArtist['artist_url'] != null) {
      final oldPath = oldArtist['artist_url'] as String;
      if (oldPath.isNotEmpty && oldPath != artistProfilePath) {
        try {
          await supabase.storage.from('artist_profiles').remove([oldPath]);
        } catch (e) {
          // Ignore if removal fails
          print('Failed to remove old artist image: $e');
        }
      }
    }

    // Update artist info in database
    await supabase
        .from('artists')
        .update({
          'name': name,
          'bio': bio,
          'about': about,
          'artist_url': artistProfilePath,
        })
        .eq('id', id);
  }

  Future<void> deleteArtist(String id) async {
    // Get artist record to find the image path
    final res = await supabase
        .from('artists')
        .select('artist_url')
        .eq('id', id)
        .maybeSingle();

    if (res != null && res['artist_url'] != null) {
      final path = res['artist_url'] as String;
      if (path.isNotEmpty) {
        try {
          // Remove image from Supabase storage
          await supabase.storage.from('artist_profiles').remove([path]);
        } catch (e) {
          // Ignore if removal fails
          print('Failed to delete artist image: $e');
        }
      }
    }

    // Delete artist from database
    await supabase.from('artists').delete().eq('id', id);
  }

  Future<void> addArtist({
    required String name,
    required String bio,
    required String artistProfilePath,
    String? about,
  }) async {
    await supabase.from('artists').insert({
      'id': uuid.v4(),
      'name': name,
      'bio': bio,
      'about': about,
      'artist_url': artistProfilePath,
    });
  }

  Future<String> uploadArtistProfile(File file, {String? oldPath}) async {
    // Remove old file if exists
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        await supabase.storage.from('artist_profiles').remove([oldPath]);
      } catch (_) {
        // ignore if removal fails
      }
    }

    // Prepare file name
    final extension = p.extension(file.path).toLowerCase();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

    // Detect content type
    String contentType;
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        contentType = 'image/jpeg';
        break;
      case '.png':
        contentType = 'image/png';
        break;
      case '.gif':
        contentType = 'image/gif';
        break;
      case '.webp':
        contentType = 'image/webp';
        break;
      default:
        contentType = 'image/jpeg'; // fallback
    }

    // Upload file
    await supabase.storage
        .from('artist_profiles')
        .uploadBinary(
          fileName,
          await file.readAsBytes(),
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    // Return public URL
    return supabase.storage.from('artist_profiles').getPublicUrl(fileName);
  }

  /// Upload from URL
  Future<String> uploadArtistProfileFromUrl(
    String url, {
    String? oldPath,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image from URL');
      }

      // Create temp file
      final tempDir = Directory.systemTemp;
      final extension = p.extension(url).toLowerCase();
      final tempFile = File(
        '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await tempFile.writeAsBytes(response.bodyBytes);

      // Upload using main function
      final uploadedPath = await uploadArtistProfile(
        tempFile,
        oldPath: oldPath,
      );

      // Delete temp file
      await tempFile.delete();

      return uploadedPath;
    } catch (e) {
      throw Exception('Error uploading image from URL: $e');
    }
  }

  // -------------------- ALBUMS --------------------
  Future<List<Album>> getAlbums() async {
    final res = await supabase.from('albums').select().order('name');
    final data = List<Map<String, dynamic>>.from(res);

    return data.map((e) {
      final albumPath = e['album_url'] as String?;
      return Album(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: e['artist_id']?.toString() ?? '',
        albumProfilePath: albumPath,
        albumProfileUrl: getStorageUrl(albumPath, 'album_covers'),
      );
    }).toList();
  }

  Future<List<Album>> getAlbumsByArtist(String artistId) async {
    final response = await supabase
        .from('albums')
        .select()
        .eq('artist_id', artistId)
        .order('name');

    return response.map<Album>((e) => Album.fromMap(e)).toList();
  }

  Future<void> addAlbum({
    required String name,
    required String artistId,
    required String albumProfilePath,
  }) async {
    await supabase.from('albums').insert({
      'id': uuid.v4(),
      'name': name,
      'artist_id': artistId,
      'album_url': albumProfilePath,
    });
  }

  Future<void> updateAlbum({
    required String id,
    required String name,
    required String artistId,
    required String albumProfilePath,
  }) async {
    await supabase
        .from('albums')
        .update({
          'name': name,
          'artist_id': artistId,
          'album_url': albumProfilePath,
        })
        .eq('id', id);
  }

  Future<void> deleteAlbum(String id) async {
    final res = await supabase
        .from('albums')
        .select('album_url')
        .eq('id', id)
        .maybeSingle();
    if (res != null && res['album_url'] != null) {
      await supabase.storage.from('album_covers').remove([res['album_url']]);
    }
    await supabase.from('albums').delete().eq('id', id);
  }

  Future<String> uploadAlbumCover(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final extension = p.extension(file.path).toLowerCase();
    String contentType;
    if (extension == '.jpg' || extension == '.jpeg') {
      contentType = 'image/jpeg';
    } else if (extension == '.png') {
      contentType = 'image/png';
    } else if (extension == '.gif') {
      contentType = 'image/gif';
    } else {
      contentType = 'image/jpeg'; // default
    }
    await supabase.storage
        .from('album_covers')
        .uploadBinary(
          fileName,
          await file.readAsBytes(),
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return fileName;
  }

  // -------------------- SONGS --------------------
  Future<List<Song>> getSongsWithDetails() async {
    final res = await supabase.from('songs').select().order('name');
    final data = List<Map<String, dynamic>>.from(res);

    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );

    return data.map((e) {
      final audioUrl = getStorageUrl(e['audio_url'] as String?, 'song_audio');

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
        artistName: artistName,
        albumImage: albumImage,
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
            storageUrl: supabase.storage.from('song_audio').getPublicUrl(''),
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
            storageUrl: supabase.storage.from('song_audio').getPublicUrl(''),
          ),
        )
        .toList();
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
    required String name,
    required String artistId,
    required String albumId,
    required String audioUrl,
  }) async {
    await supabase
        .from('songs')
        .update({
          'name': name,
          'artist_id': artistId,
          'album_id': albumId,
          'audio_url': audioUrl,
        })
        .eq('id', id);
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

  Future<String> uploadSongAudio(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    await supabase.storage
        .from('song_audio')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('song_audio').getPublicUrl(fileName);
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
      final audioUrl = getStorageUrl(e['audio_url'] as String?, 'song_audio');
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
      final audioUrl = getStorageUrl(e['audio_url'] as String?, 'song_audio');
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
      final audioUrl = e['audio_url'] as String?;
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
}
