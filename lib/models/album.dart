import 'package:supabase_flutter/supabase_flutter.dart';

class Album {
  final String id;
  final String name;
  final String artistId;
  final String? albumProfilePath;
  String? albumProfileUrl;
  Album({
    required this.id,
    required this.name,
    required this.artistId,
    this.albumProfilePath,
    this.albumProfileUrl,
  });

  factory Album.fromMap(Map<String, dynamic> map, {SupabaseClient? supabase}) {
    final path = map['album_url'] as String?;
    String? url;
    if (path != null && supabase != null) {
      // If the path is already a full URL, use it directly
      if (path.startsWith('http')) {
        url = path;
      } else {
        url = supabase.storage.from('album_covers').getPublicUrl(path);
      }
    }
    return Album(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      artistId: map['artist_id']?.toString() ?? '',
      albumProfilePath: path, // store DB path
      albumProfileUrl: url, // full URL for UI
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist_id': artistId,
      'album_url': albumProfilePath, // must match DB column
    };
  }
}
