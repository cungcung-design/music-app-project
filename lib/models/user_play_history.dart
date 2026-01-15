class UserPlayHistory {
  final String id;       
  final String userId;  
  final String songId;   
  final DateTime playedAt;

  UserPlayHistory({
    required this.id,
    required this.userId,
    required this.songId,
    required this.playedAt,
  });

  /// Create model from Supabase row (Map)
  factory UserPlayHistory.fromMap(Map<String, dynamic> map) {
    return UserPlayHistory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      songId: map['song_id'] as String,
      playedAt: DateTime.parse(map['played_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,      
      'user_id': userId,
      'song_id': songId,
      'played_at': playedAt.toIso8601String(),
    };
  }
}
