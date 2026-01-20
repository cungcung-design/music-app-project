import 'package:supabase_flutter/supabase_flutter.dart';

class Album {
  final String id;
  final String name;
  final String artistId;
  final String? albumProfileUrl;

  Album({
    required this.id,
    required this.name,
    required this.artistId,
    this.albumProfileUrl,
  });

  static String? resolveUrl({
    required SupabaseClient supabase,
    required String bucket,
    String? value,
  }) {
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return supabase.storage.from(bucket).getPublicUrl(value);
  }

  factory Album.fromMap(
    Map<String, dynamic> map, {
    required SupabaseClient supabase,
  }) {
    final raw = map['album_url'] as String?;
    String? url;
    if (raw != null && raw.isNotEmpty) {
      url = resolveUrl(supabase: supabase, bucket: 'album_covers', value: raw);
    }

    return Album(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      artistId: map['artist_id'].toString(),
      albumProfileUrl: url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist_id': artistId,
      'album_url': albumProfileUrl,
    };
  }
}
