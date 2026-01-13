import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  AudioPlayer get player => _player;

  // Streams for the Seek Bar
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  Future<void> play(String url) async {
    if (_currentUrl == url && _player.state == PlayerState.playing) {
      await _player.pause();
    } else if (_currentUrl == url && _player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      _currentUrl = url;
      await _player.stop();
      await _player.play(UrlSource(url));
    }
  }

  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> stop() async => await _player.stop();
}