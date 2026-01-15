import 'song.dart';
import 'artist.dart';

class SuggestedData {
  final List<Song> recentlyPlayed;
  final List<Song> popularSongs;
  final List<Artist> artists;

  SuggestedData({
    required this.recentlyPlayed,
    required this.popularSongs,
    required this.artists,
  });
}
