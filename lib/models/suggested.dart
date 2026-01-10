import 'song.dart';
import 'artist.dart';

class SuggestedData {
  final List<Song> recentlyPlayed;
  final List<Song> recommended;
  final List<Artist> artists;

  SuggestedData({
    required this.recentlyPlayed,
    required this.recommended,
    required this.artists,
  });
}
