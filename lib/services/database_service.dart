import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/profile.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ================= AUTH =================
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _createProfileIfNotExists(
        userId: res.user!.id,
        email: email,
        name: name,
      );
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

  Future<void> logout() async => await supabase.auth.signOut();

  // ================= PROFILE =================
  Future<Profile?> getProfile(String userId) async {
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res != null ? Profile.fromMap(res) : null;
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
    required String dob,
    required String country,
    String? avatarUrl,
  }) async {
    await supabase
        .from('profiles')
        .update({
          'name': name,
          'dob': dob,
          'country': country,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        })
        .eq('id', userId);
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final fileName = p.basename(file.path);
    final path = 'avatars/$userId/$fileName';
    final bytes = await file.readAsBytes();

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true),
        );

    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _createProfileIfNotExists({
    required String userId,
    required String email,
    required String name,
  }) async {
    final existing = await getProfile(userId);
    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'name': name,
      });
    }
  }

  // ================= SONGS =================
  Future<List<Song>> getSongs() async {
    print('Current user: ${supabase.auth.currentUser}'); // Debug: check auth
    final res = await supabase.from('songs').select().order('created_at');
    print('Songs query result: $res'); // Debug: check what Supabase returns

    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(res);

    return data.map((e) {
      String? audioPath = e['audio_url']; // path stored in table
      String? audioUrl;
      if (audioPath != null && audioPath.isNotEmpty) {
        audioUrl = supabase.storage
            .from('song_audio')
            .getPublicUrl(audioPath); // correct bucket
      }
      return Song(
        id: e['id'],
        name: e['name'],
        artistId: e['artist_id'],
        albumId: e['album_id'],
        audioUrl: audioUrl,
      );
    }).toList();
  }

  Future<void> addSong({
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

  Future<void> deleteSong(String id) async =>
      await supabase.from('songs').delete().eq('id', id);

  // ================= ARTISTS =================
  Future<List<Artist>> getArtists() async {
    final res = await supabase.from('artists').select().order('name');
    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(res);

    return data.map((e) {
      String? profilePath = e['profile_url'];
      String? profileUrl;
      if (profilePath != null && profilePath.isNotEmpty) {
        profileUrl = supabase.storage
            .from('artist_profiles')
            .getPublicUrl(profilePath);
      }
  return Artist(
     id: e['id'].toString(),    // ✅ STRING
      name: e['name'] as String,
      bio: e['bio'] as String,
      profileUrl: profileUrl,
    );
    }).toList();
  }

  Future<void> addArtist({
    required String name,
    required String bio,
    required String profileUrl,
  }) async {
    await supabase.from('artists').insert({
      'name': name,
      'bio': bio,
      'profile_url': profileUrl,
    });
  }

  Future<void> updateArtist({
    required String id,
    required String name,
    required String bio,
    required String profileUrl,
  }) async {
    await supabase
        .from('artists')
        .update({'name': name, 'bio': bio, 'profile_url': profileUrl})
        .eq('id', id);
  }

  Future<void> deleteArtist(String id) async =>
      await supabase.from('artists').delete().eq('id', id);

  // ================= ALBUMS =================
  Future<List<Album>> getAlbums() async {
    final res = await supabase.from('albums').select().order('name');
    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(res);

    return data.map((e) {
      String? coverPath = e['cover_url'];
      String? coverUrl;
      if (coverPath != null && coverPath.isNotEmpty) {
        coverUrl = supabase.storage
            .from('album_covers')
            .getPublicUrl(coverPath);
      }
      return Album(
        id: e['id'],
        name: e['name'],
        artistId: e['artist_id'],
        coverUrl: coverUrl,
      );
    }).toList();
  }

  Future<void> addAlbum({
    required String name,
    required String artistId,
    required String coverUrl,
  }) async {
    await supabase.from('albums').insert({
      'name': name,
      'artist_id': artistId,
      'cover_url': coverUrl,
    });
  }

  Future<void> updateAlbum({
    required String id,
    required String name,
    required String artistId,
    required String coverUrl,
  }) async {
    await supabase
        .from('albums')
        .update({'name': name, 'artist_id': artistId, 'cover_url': coverUrl})
        .eq('id', id);
  }

  Future<void> deleteAlbum(String id) async =>
      await supabase.from('albums').delete().eq('id', id);

  // ================= STORAGE =================
  Future<String> uploadArtistProfile(File file) async {
    final fileName =
        'artists/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    await supabase.storage
        .from('artist_profiles')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return fileName; // store path in DB
  }

  Future<String> uploadSongAudio(File file) async {
    final fileName =
        'songs/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    await supabase.storage
        .from('song_audio') // ✅ make sure bucket name is correct
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return fileName;
  }

  Future<String> uploadAlbumCover(File file) async {
    final fileName =
        'albums/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    await supabase.storage
        .from('album_covers')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return fileName;
  }
}
