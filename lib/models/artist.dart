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

  static String? resolveUrl({
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

  factory Artist.fromMap(Map<String, dynamic> map, {SupabaseClient? supabase}) {
    final path = map['artist_url'] as String?;
    String? url;
    if (path != null && supabase != null) {
      url = resolveUrl(
        supabase: supabase,
        bucket: 'artist_profiles',
        value: path,
      );
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
