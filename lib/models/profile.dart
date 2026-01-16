import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String email;
  final String? name;
  final String? avatarPath;
  String? avatarUrl;
  final String? dob;
  final String? country;
  final String? role;

  Profile({
    required this.id,
    required this.email,
    this.name,
    this.avatarPath,
    this.avatarUrl,
    this.dob,
    this.country,
    this.role,
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

  /// Convert from Supabase row (Map) to Profile object
  factory Profile.fromMap(
    Map<String, dynamic> map, {
    SupabaseClient? supabase,
  }) {
    final path = map['avatar_url'] as String?;
    String? url;

    if (path != null && path.isNotEmpty && supabase != null) {
      try {
        url = resolveUrl(supabase: supabase, bucket: 'profiles', value: path);
      } catch (_) {
        url = null; // If file missing or invalid, fallback to null
      }
    }

    return Profile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatarPath: path,
      avatarUrl: url,
      dob: map['dob'],
      country: map['country'],
      role: map['role'],
    );
  }
}
