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
    // Check if URL contains placeholder (not configured)
    if (url.contains('your_supabase_url')) return null;
    print('Generated URL for $bucket/$path: $url');
    return url;
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

  // ===================== ARTISTS =====================
  // Get all artists
  Future<List<Artist>> getArtists() async {
    final data = await supabase.from('artists').select();
    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Artist.fromMap(e, supabase: supabase)).toList();
  }

  // Add new artist with image
  Future<void> addArtist({
    required String name,
    String? bio,
    String? about,
    Uint8List? imageBytes, // optional artist image
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      final path = 'artist_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage
          .from('artist_profiles')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );
      imageUrl = path;
    }

    await supabase.from('artists').insert({
      'name': name,
      'bio': bio ?? '',
      'about': about,
      'artist_url': imageUrl,
    });
  }

  // Update artist info & image
  Future<void> updateArtist({
    required String artistId,
    String? name,
    String? bio,
    String? about,
    Uint8List? newImageBytes,
  }) async {
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (bio != null) updateData['bio'] = bio;
    if (about != null) updateData['about'] = about;

    if (newImageBytes != null) {
      // Upload new image
      final path = 'artist_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage
          .from('artist_profiles')
          .uploadBinary(
            path,
            newImageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );
      updateData['artist_url'] = path;
    }

    await supabase.from('artists').update(updateData).eq('id', artistId);
  }

  // Delete artist (also deletes related albums if cascade is set in SQL)
  Future<void> deleteArtist(String artistId) async {
    // First, get the artist's image URL to delete from storage
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
    // Then delete the artist (cascade will handle related albums and songs)
    await supabase.from('artists').delete().eq('id', artistId);
  }

  // ===================== ALBUMS =====================
  // Get all albums
  Future<List<Album>> getAlbums() async {
    final data = await supabase.from('albums').select();
    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Album.fromMap(e, supabase: supabase)).toList();
  }

  // Add new album with cover image
  Future<void> addAlbum({
    required String name,
    required String artistId,
    File? coverFile, // optional album cover
  }) async {
    String? albumUrl;
    if (coverFile != null) {
      final path = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage.from('album_covers').upload(path, coverFile);
      albumUrl = path;
    }

    await supabase.from('albums').insert({
      'name': name,
      'artist_id': artistId,
      'album_url': albumUrl,
    });
  }

  // Update album info & cover
  Future<void> updateAlbum({
    required String albumId,
    String? name,
    String? artistId,
    File? newCoverFile,
  }) async {
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (artistId != null) updateData['artist_id'] = artistId;

    if (newCoverFile != null) {
      final path = 'album_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage.from('album_covers').upload(path, newCoverFile);
      updateData['album_url'] = path;
    }

    await supabase.from('albums').update(updateData).eq('id', albumId);
  }

  // Delete album
  Future<void> deleteAlbum(String albumId) async {
    await supabase.from('albums').delete().eq('id', albumId);
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

  // ===================== GET PUBLIC URL FOR IMAGE =====================
  String getPublicUrl(String bucket, String path) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<List<Song>> getSongs() async {
    final res = await supabase.from('songs').select();
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

  Future<String> addSong({
    required String name,
    required String artistId,
    required String albumId,
    required String audioUrl,
  }) async {
    await supabase.from('songs').insert({
      'name': name,
      'artist_id': artistId,
      'album_id': albumId,
      'audio_url': audioUrl,
    });
    // Get the generated id
    final inserted = await supabase
        .from('songs')
        .select('id')
        .eq('name', name)
        .single();
    return inserted['id'] as String;
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
