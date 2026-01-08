class Album {
  final String id;
  final String name;
  final String artistId;
  final String? coverUrl;

  Album({
    required this.id,
    required this.name,
    required this.artistId,
    this.coverUrl,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      name: map['name'],
      artistId: map['artist_id'],
      coverUrl: map['cover_url'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'artist_id': artistId,
        'cover_url': coverUrl,
      };
}
