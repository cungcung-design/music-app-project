import 'dart:async';
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
import '../models/storage_song.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid uuid = const Uuid();

  final StreamController<void> _favoritesController =
      StreamController<void>.broadcast();

  Stream<void> get favoritesChanged => _favoritesController.stream;

  void notifyFavoritesChanged() {
    _favoritesController.add(null);
  }

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

    return supabase.storage.from(bucket).getPublicUrl(value);
  }

  static String? resolveImageUrl(String? value, String bucket) {
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return Supabase.instance.client.storage.from(bucket).getPublicUrl(value);
  }

  // -------------------- AUTH --------------------
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    // Check if user already exists in auth system first
    try {
      // Try to sign up - Supabase will reject if email exists
      final res = await supabase.auth.signUp(email: email, password: password);

      if (res.user == null) {
        throw Exception('Signup failed - user not created');
      }

      final userId = res.user!.id;

      // Create profile after successful signup
      // Use try-catch to handle case where profile might already exist
      try {
        await createProfileIfNotExists(userId, email, name, role: role);
      } catch (e) {
        // If profile creation fails, user is still created in auth
        // Log error but don't fail the entire signup
        print('Profile creation note: $e');
      }

      return userId;
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        throw Exception('An account with this email already exists');
      }
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    final trimmedEmail = email.trim();
    print('Attempting login for email: $trimmedEmail');

    try {
      final res = await supabase.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      print(
          'Login response received. User: ${res.user?.id}, Session: ${res.session != null}');

      if (res.user == null) {
        throw Exception('Login failed - user not found');
      }

      if (res.session == null) {
        throw Exception('Login failed - session not created');
      }

      print('Login successful for user: ${res.user!.id}');
    } catch (e) {
      print('Login error: $e');
      // Re-throw other errors with context
      if (e.toString().contains('400') ||
          e.toString().contains('Bad Request')) {
        throw Exception(
            'Invalid request. Please check your email and password format.');
      }
      rethrow;
    }
  }

  Future<void> logout() async => supabase.auth.signOut();

  // -------------------- PROFILE --------------------
  Future<Profile?> getProfile(String userId) async {
    print('getProfile: fetching profile for userId = $userId');
    final data =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    print('getProfile: data received = $data');
    if (data != null) {
      try {
        final profile = Profile.fromMap(
          data as Map<String, dynamic>,
          supabase: supabase,
        );
        print('getProfile: successfully created profile for ${profile.name}');
        return profile;
      } catch (error) {
        print('getProfile: error creating profile: $error');
        return null;
      }
    } else {
      print('getProfile: no data found for userId = $userId');
      return null;
    }
  }

  // -------------------------------
  // GET CURRENT USER PROFILE
  // -------------------------------
  Future<Profile?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    print('getUserProfile: currentUser = ${user?.id}');
    if (user == null) return null;
    return getProfile(user.id);
  }

  // -------------------------------
  // GET PROFILE BY EMAIL
  // -------------------------------
  Future<Profile?> getProfileByEmail(String email) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();
    if (data != null) {
      return Profile.fromMap(data as Map<String, dynamic>, supabase: supabase);
    }
    return null;
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
    // Build update data map
    final Map<String, dynamic> updateData = {
      'name': name,
    };

    if (dob != null) {
      updateData['dob'] = dob;
    }
    if (country != null) {
      updateData['country'] = country;
    }
    if (avatarPath != null) {
      updateData['avatar_url'] = avatarPath;
    }

    // Try UPDATE first - this avoids SELECT query that might cause recursion
    try {
      final result = await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .maybeSingle();

      // If no rows were updated, the profile doesn't exist - insert it
      if (result == null) {
        updateData['id'] = userId;
        updateData['email'] = supabase.auth.currentUser?.email ?? '';
        await supabase.from('profiles').insert(updateData);
      }
    } catch (e) {
      // If UPDATE fails due to no matching row, try INSERT
      final errorString = e.toString();
      if (errorString.contains('No rows found') ||
          errorString.contains('no rows') ||
          errorString.contains('PGRST116') ||
          errorString.contains('0 rows')) {
        updateData['id'] = userId;
        updateData['email'] = supabase.auth.currentUser?.email ?? '';
        await supabase.from('profiles').insert(updateData);
      } else {
        rethrow;
      }
    }
  }

  // -------------------------------
  // UPDATE USER ROLE
  // -------------------------------
  Future<void> updateUserRole(String userId, String role) async {
    await supabase.from('profiles').update({'role': role}).eq('id', userId);
  }

  // -------------------------------
  // SAVE PROFILE (with default name if null)
  // -------------------------------
  Future<void> saveProfile(Profile profile) async {
    final user = currentUser;
    if (user == null) return;

    final nameToSave = (profile.name == null || profile.name!.isEmpty)
        ? 'Unknown'
        : profile.name!;

    await updateProfile(
      userId: user.id,
      name: nameToSave,
      dob: profile.dob,
      country: profile.country,
      avatarPath: profile.avatarPath,
    );
  }

  // -------------------------------
  // UPLOAD AVATAR (OPTIONAL)
  // -------------------------------
  Future<String> uploadAvatar(String userId, Uint8List bytes,
      {required String fileExtension}) async {
    final String fileName = '$userId.$fileExtension';

    await supabase.storage.from('profiles').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$fileExtension',
          ),
        );

    return fileName;
  }

  // -------------------------------
  // CREATE PROFILE IF NOT EXISTS
  // -------------------------------
  Future<void> createProfileIfNotExists(
      String userId, String email, String name,
      {String role = 'user'}) async {
    try {
      // Try to insert directly - if it fails because profile exists, that's okay
      await supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // If profile already exists (duplicate key error), that's fine
      // Only throw if it's a different error
      final errorString = e.toString();
      if (!errorString.contains('duplicate') &&
          !errorString.contains('unique') &&
          !errorString.contains('already exists')) {
        rethrow;
      }
      // Profile already exists, which is what we want
    }
  }

  // -------------------------------
  // INSERT ADMIN PROFILE
  // -------------------------------
  Future<void> insertAdminProfile() async {
    await supabase.from('profiles').insert({
      'id': '45b98987-fbc0-4ac4-a38b-dff11008f7fc',
      'email': 'admin@gmail.com',
      'name': 'Admin',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // -------------------------------
  // GET ALL USERS
  // -------------------------------
  Future<List<Profile>> getAllUsers() async {
    final res = await supabase.from('profiles').select().order('name');
    final data = List<Map<String, dynamic>>.from(res);
    print('getAllUsers: fetched ${data.length} profiles');

    return data.map((e) {
      try {
        final profile = Profile.fromMap(e, supabase: supabase);
        print('getAllUsers: successfully created profile for ${profile.name}');
        return profile;
      } catch (error) {
        print('getAllUsers: error creating profile for ${e['name']}: $error');
        return Profile(
          id: e['id'] ?? '',
          name: e['name'] ?? 'Unknown',
          email: e['email'] ?? '',
        );
      }
    }).toList();
  }

  // ADD USER
  // -------------------------------
  Future<void> addUser({
    required String name,
    required String email,
    String? country,
    String? avatarPath,
  }) async {
    final id = const Uuid().v4();

    await supabase.from('profiles').insert({
      'id': id,
      'name': name,
      'email': email,
      if (country != null) 'country': country,
      if (avatarPath != null) 'avatar_url': avatarPath,
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
    final data = await supabase.from('artists').select().order('order');
    final artists = List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Artist.fromMap(e, supabase: supabase)).toList();
    return artists;
  }

  Future<Artist?> getArtistById(String artistId) async {
    final data = await supabase
        .from('artists')
        .select()
        .eq('id', artistId)
        .maybeSingle();
    if (data != null) {
      return Artist.fromMap(data as Map<String, dynamic>, supabase: supabase);
    }
    return null;
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
      await supabase.storage.from('artist_profiles').uploadBinary(
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
      await supabase.storage.from('artist_profiles').uploadBinary(
            path,
            newImageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType ?? 'image/png',
            ),
          );
      updateData['artist_url'] =
          supabase.storage.from('artist_profiles').getPublicUrl(path);
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

  Future<void> updateArtistOrder(String artistId, int order) async {
    await supabase.from('artists').update({'order': order}).eq('id', artistId);
  }

  // ================= TABLE ALBUMS =================

  Future<List<Album>> getAlbums() async {
    final res = await supabase.from('albums').select('*, songs(id)');
    return List<Map<String, dynamic>>.from(
      res,
    ).map((e) => Album.fromMap(e, supabase: supabase)).toList();
  }

  // ================= STORAGE ALBUMS =================

  Future<List<Album>> fetchAlbumsFromStorage() async {
    final files =
        await supabase.storage.from('album_covers').list(path: 'albums');

    return files.map((file) {
      final url = supabase.storage
          .from('album_covers')
          .getPublicUrl('albums/${file.name}');

      final name = file.name.substring(0, file.name.lastIndexOf('.'));

      return Album(id: name, name: name, artistId: '', albumProfileUrl: url);
    }).toList();
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
      await supabase.storage.from('album_covers').upload(
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
      await supabase.storage.from('album_covers').uploadBinary(
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

      await supabase.storage.from('album_covers').upload(
            path,
            newCoverFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      updateData['album_url'] = path;
    } else if (newCoverBytes != null) {
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

      await supabase.storage.from('album_covers').uploadBinary(
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

  Future<List<Album>> getAlbumsByArtist(String artistId) async {
    final res =
        await supabase.from('albums').select().eq('artist_id', artistId);
    return List<Map<String, dynamic>>.from(
      res,
    ).map((e) => Album.fromMap(e, supabase: supabase)).toList();
  }

  Future<Map<String, String>> getAlbumCoverMap() async {
    final res = await supabase.from('albums').select('id, album_url');
    final Map<String, String> albumMap = {};
    for (final row in res) {
      final albumId = row['id'].toString();
      final albumUrl = row['album_url']?.toString();
      if (albumUrl != null) {
        final fullUrl = albumUrl.startsWith('http')
            ? albumUrl
            : supabase.storage.from('album_covers').getPublicUrl(albumUrl);
        albumMap[albumId] = fullUrl;
      }
    }
    return albumMap;
  }

  //===================== SONGS =====================
  Future<List<Song>> getSongs() async {
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

  Future<Map<String, String>> fetchSongAudioMap() async {
    final files = await supabase.storage.from('song_audio').list(path: '');

    final Map<String, String> audioMap = {};

    for (final file in files) {
      if (file.name.endsWith('.mp3')) {
        final songId = file.name.replaceAll('.mp3', '');
        final url = supabase.storage.from('song_audio').getPublicUrl(file.name);

        audioMap[songId] = url;
      }
    }

    return audioMap;
  }

  Future<List<StorageSong>> fetchSongsFromStorage() async {
    final files = await supabase.storage.from('song_audio').list(path: '');

    const audioExtensions = ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac'];

    return files.where((file) {
      final ext = file.name.split('.').last.toLowerCase();
      return audioExtensions.contains(ext);
    }).map((file) {
      final url = supabase.storage.from('song_audio').getPublicUrl(file.name);

      final id = file.name.substring(0, file.name.lastIndexOf('.'));

      return StorageSong(id: id, name: id, url: url);
    }).toList();
  }

  Future<List<Song>> getSongsWithDetails() async {
    final res = await supabase.from('songs').select().order('created_at');
    final data = List<Map<String, dynamic>>.from(res);
    final albumMap = await getAlbumCoverMap();
    final artistMap = Map<String, String>.fromEntries(
      (await supabase.from('artists').select()).map(
        (e) => MapEntry(e['id'].toString(), e['name'].toString()),
      ),
    );
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
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
        order: index,
      );
    }).toList();
  }

  Future<List<Song>> getSongsByArtist(String artistId) async {
    final res = await supabase.from('songs').select().eq('artist_id', artistId);
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

  Future<List<Song>> getSongsByAlbum(String albumId) async {
    final res = await supabase.from('songs').select().eq('album_id', albumId);
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

  Future<String> uploadSongAudio({
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (file == null && bytes == null) {
      throw Exception('Either file or bytes must be provided');
    }

    final baseFileName = fileName ??
        (file != null
            ? p.basename(file.path)
            : 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

    final storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$baseFileName';

    if (file != null) {
      await supabase.storage.from('song_audio').upload(
            storageFileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      await supabase.storage.from('song_audio').uploadBinary(
            storageFileName,
            bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    return storageFileName;
  }

  Future<void> addSong({
    required String id,
    required String name,
    required String artistId,
    required String albumId,
    required String audioUrl,
  }) async {
    await supabase.from('songs').insert({
      'id': id,
      'name': name,
      'artist_id': artistId,
      'album_id': albumId,
      'audio_url': audioUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateSong({
    required String id,
    String? name,
    String? artistId,
    String? albumId,
    String? audioUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (name != null && name.isNotEmpty) data['name'] = name;
      if (artistId != null && artistId.isNotEmpty) data['artist_id'] = artistId;
      if (albumId != null && albumId.isNotEmpty) data['album_id'] = albumId;

      if (audioUrl != null && audioUrl.isNotEmpty) {
        final currentSong = await supabase
            .from('songs')
            .select('audio_url')
            .eq('id', id)
            .maybeSingle();

        if (currentSong != null && currentSong['audio_url'] != null) {
          final String oldAudioUrl = currentSong['audio_url'];

          if (!oldAudioUrl.startsWith('http')) {
            await supabase.storage.from('song_audio').remove([oldAudioUrl]);
          }
        }
        data['audio_url'] = audioUrl;
      }

      if (data.isEmpty) return;

      await supabase.from('songs').update(data).eq('id', id);
    } catch (e) {
      throw Exception("Update failed: $e");
    }
  }

  Future<void> deleteSong(String id) async {
    final song = await supabase
        .from('songs')
        .select('audio_url')
        .eq('id', id)
        .maybeSingle();

    if (song != null && song['audio_url'] != null) {
      final audioUrl = song['audio_url'] as String;
      if (!audioUrl.startsWith('http')) {
        await supabase.storage.from('song_audio').remove([audioUrl]);
      }
    }

    await supabase.from('songs').delete().eq('id', id);
  }

  Future<String> replaceSongAudio({
    required String songId,
    required Uint8List newBytes,
    required String fileName,
  }) async {
    final old = await supabase
        .from('songs')
        .select('audio_url')
        .eq('id', songId)
        .maybeSingle();

    if (old != null && old['audio_url'] != null) {
      await supabase.storage.from('song_audio').remove([old['audio_url']]);
    }

    final newPath = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage.from('song_audio').uploadBinary(
          newPath,
          newBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await supabase
        .from('songs')
        .update({'audio_url': newPath}).eq('id', songId);

    return newPath;
  }

  // -------------------- FAVORITES --------------------
  Future<void> addToFavorites(String songId) async {
    final user = currentUser;
    if (user == null) return;

    // Check if already favorite
    final existing = await supabase
        .from('user_favorites')
        .select()
        .eq('user_id', user.id)
        .eq('song_id', songId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('user_favorites').insert({
        'id': uuid.v4(),
        'user_id': user.id,
        'song_id': songId,
        'created_at': DateTime.now().toIso8601String(),
      });
      notifyFavoritesChanged();
    }
  }

  Future<void> removeFromFavorites(String songId) async {
    final user = currentUser;
    if (user == null) return;
    await supabase
        .from('user_favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('song_id', songId);
    notifyFavoritesChanged();
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

    final res = await supabase.from('user_favorites').select('''
        songs (
          id,
          name,
          audio_url,
          album_id,
          artist_id,
          artists (name),
          albums (album_url)
        )
      ''').eq('user_id', user.id);

    final data = List<Map<String, dynamic>>.from(res);

    return data.where((item) => item['songs'] != null).map((item) {
      final e = item['songs'] as Map<String, dynamic>;

      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );

      final artistName = e['artists']?['name'];

      final albumImage = e['albums']?['album_url'] != null
          ? resolveUrl(
              supabase: supabase,
              bucket: 'album_covers',
              value: e['albums']['album_url'],
            )
          : null;

      return Song(
        id: e['id'] as String,
        name: e['name'] ?? '',
        artistId: e['artist_id'] as String,
        albumId: e['album_id'] as String,
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUserFavoritesRaw() async {
    final user = currentUser;
    if (user == null) return [];

    final res =
        await supabase.from('user_favorites').select().eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<int> getTotalFavoriteSongsCount() async {
    final res = await supabase.from('user_favorites').select('id');
    return res.length;
  }

  Future<List<Song>> getUserFavorites(String userId) async {
    final res = await supabase.from('user_favorites').select('''
        songs (
          id,
          name,
          audio_url,
          album_id,
          artist_id,
          artists (name),
          albums (album_url)
        )
      ''').eq('user_id', userId);

    final data = List<Map<String, dynamic>>.from(res);

    return data.where((item) => item['songs'] != null).map((item) {
      final e = item['songs'] as Map<String, dynamic>;

      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );

      final artistName = e['artists']?['name'];

      final albumImage = e['albums']?['album_url'] != null
          ? resolveUrl(
              supabase: supabase,
              bucket: 'album_covers',
              value: e['albums']['album_url'],
            )
          : null;

      return Song(
        id: e['id'] as String,
        name: e['name'] ?? '',
        artistId: e['artist_id'] as String,
        albumId: e['album_id'] as String,
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

  // -------------------- POPULAR SONGS --------------------
  Future<List<Song>> getPopularSongs({int limit = 5}) async {
    final songsRes = await supabase
        .from('songs')
        .select()
        .order('play_count', ascending: false)
        .limit(limit);
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

  // -------------------- ADD TO PLAY HISTORY --------------------
  Future<void> addToPlayHistory(String songId) async {
    final user = currentUser;
    if (user == null) return;

    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final recentPlay = await supabase
        .from('user_play_history')
        .select('id')
        .eq('user_id', user.id)
        .eq('song_id', songId)
        .gte('played_at', fiveMinutesAgo.toIso8601String())
        .maybeSingle();

    if (recentPlay != null) {
      // Update the existing entry's played_at timestamp
      await supabase
          .from('user_play_history')
          .update({'played_at': DateTime.now().toIso8601String()}).eq(
              'id', recentPlay['id']);
    } else {
      // Insert a new entry
      await supabase.from('user_play_history').insert({
        'id': uuid.v4(),
        'user_id': user.id,
        'song_id': songId,
        'played_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // -------------------- GET RECENTLY PLAYED SONGS --------------------
  Future<List<Song>> getRecentlyPlayedSongs({int limit = 5}) async {
    final user = currentUser;
    if (user == null) return [];

    final res = await supabase
        .from('user_play_history')
        .select('''
        songs (
          id,
          name,
          audio_url,
          album_id,
          artist_id,
          artists (name),
          albums (album_url)
        )
      ''')
        .eq('user_id', user.id)
        .order('played_at', ascending: false)
        .limit(limit);

    final data = List<Map<String, dynamic>>.from(res);

    return data.map((item) {
      final e = item['songs'] as Map<String, dynamic>;

      // Resolve Audio URL
      final audioUrl = resolveUrl(
        supabase: supabase,
        bucket: 'song_audio',
        value: e['audio_url'],
      );

      // Get metadata from the joined response
      final artistName = e['artists']?['name'];
      final albumImage = e['albums']?['album_url'] != null
          ? resolveUrl(
              supabase: supabase,
              bucket: 'album_covers',
              value: e['albums']['album_url'],
            )
          : null;

      return Song(
        id: e['id'].toString(),
        name: e['name'] ?? '',
        artistId: e['artist_id']?.toString() ?? '',
        albumId: e['album_id']?.toString() ?? '',
        audioUrl: audioUrl,
        albumImage: albumImage,
        artistName: artistName,
      );
    }).toList();
  }

  // -------------------- ORPHANED SONGS --------------------
  Future<List<String>> getOrphanedSongs() async {
    final storageSongs = await fetchSongsFromStorage();
    final dbSongs = await getSongs();

    final dbSongUrls =
        dbSongs.map((s) => s.audioUrl).where((url) => url != null).toSet();

    return storageSongs
        .where((storageSong) => !dbSongUrls.contains(storageSong.url))
        .map((storageSong) => storageSong.url)
        .toList();
  }

  Future<void> addOrphanedSongsToTable() async {
    final orphanedUrls = await getOrphanedSongs();

    for (final url in orphanedUrls) {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final songName = fileName.split('.').first.replaceAll('_', ' ');

      await addSong(
        id: uuid.v4(),
        name: songName,
        artistId: '',
        albumId: '',
        audioUrl: url,
      );
    }
  }
}
