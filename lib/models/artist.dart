import 'package:supabase_flutter/supabase_flutter.dart';

class Artist {
  final String id;
  final String name;
  final String? about;
  final String bio;
  final String? artistProfilePath; // file name in Supabase
  String? artistProfileUrl; // public URL

  Artist({
    required this.id,
    required this.name,
    this.about,
    required this.bio,
    this.artistProfilePath,
    this.artistProfileUrl,
  });

  factory Artist.fromMap(Map<String, dynamic> map, {SupabaseClient? supabase}) {
    final path = map['artist_url'] as String?;
    String? url;
    if (path != null && supabase != null) {
      if (path.startsWith('http')) {
        url = path;
      } else {
        url = supabase.storage.from('artist_profiles').getPublicUrl(path);
      }
    }
    return Artist(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      about: map['about'],
      artistProfilePath: path,
      artistProfileUrl: url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'about': about,
      'artist_url': artistProfilePath,
    };
  }
}
