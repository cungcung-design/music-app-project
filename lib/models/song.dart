class Song {
  final String id;
  final String name;
  final String artistId;
  final String albumId;
  final String? audioUrl;
  final String? artistName;
  final String? albumImage;
  final int? playCount;
  final Duration? duration;
  final int order;

  Song({
    required this.id,
    required this.name,
    required this.artistId,
    required this.albumId,
    this.audioUrl,
    this.artistName,
    this.albumImage,
    this.playCount,
    this.duration,
    this.order = 0,
  });

  /// Convert DB map into Song object
  factory Song.fromMap(Map<String, dynamic> map, {String? storageUrl}) {
    final path = map['audio_url'] as String?;
    String? url;

    if (path != null) {
      if (path.startsWith('http')) {
        url = path; // already full URL
      } else if (storageUrl != null) {
        url = '$storageUrl/$path'; // generate public URL
      }
    }

    return Song(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      artistId: map['artist_id']?.toString() ?? '',
      albumId: map['album_id']?.toString() ?? '',
      audioUrl: url,
      artistName: null,
      albumImage: null,
      playCount: map['play_count'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist_id': artistId,
      'album_id': albumId,
      'audio_url': audioUrl,
      'play_count': playCount,
    };
  }

  Song copyWith({
    String? id,
    String? name,
    String? artistId,
    String? albumId,
    String? audioUrl,
    String? artistName,
    String? albumImage,
    int? playCount,
    Duration? duration,
    int? order,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      audioUrl: audioUrl ?? this.audioUrl,
      artistName: artistName ?? this.artistName,
      albumImage: albumImage ?? this.albumImage,
      playCount: playCount ?? this.playCount,
      duration: duration ?? this.duration,
      order: order ?? this.order,
    );
  }
}
