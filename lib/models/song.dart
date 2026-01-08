class Song {
  final String id;
  final String name;
  final String artistId;
  final String albumId;
  final String? audioUrl;

  Song({
    required this.id,
    required this.name,
    required this.artistId,
    required this.albumId,
    this.audioUrl,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      name: map['name'],
      artistId: map['artist_id'],
      albumId: map['album_id'],
      audioUrl: map['audio_url'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'artist_id': artistId,
        'album_id': albumId,
        'audio_url': audioUrl,
      };
}
