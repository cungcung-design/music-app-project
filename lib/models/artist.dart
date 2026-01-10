class Artist {
  final String id;
  final String name;
  final String? about;
  final String bio;
  final String? artistProfilePath; // file name in Supabase
  String? artistProfileUrl;        // public URL

  Artist({
    required this.id,
    required this.name,
    this.about,
    required this.bio,
    this.artistProfilePath,
    this.artistProfileUrl,
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    final path = map['artist_url'] as String?;
    final fullUrl = path != null
        ? 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/artist_profiles/$path'
        : null;

    return Artist(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      about: map['about'],
      artistProfilePath: path,
      artistProfileUrl: fullUrl,
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
