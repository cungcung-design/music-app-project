class Artist {
  final String id;
  final String name;
  final String bio;
  final String? profileUrl;

  Artist({
    required this.id,
    required this.name,
    required this.bio,
    this.profileUrl,
  });

factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String, // ✅ STRING ID
      name: map['name'] as String,
      bio: map['bio'] as String,
      profileUrl: map['profile_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'bio': bio,
        'profile_url': profileUrl,
      };
}
