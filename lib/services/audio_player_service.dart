import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _player.onPlayerStateChanged.listen((_) {
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _cachedDuration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((event) {
      if (_playlist.isNotEmpty) {
        playNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Song? currentSong;
  Duration? _cachedDuration;
  Duration _currentPosition = Duration.zero;
  List<Song> _playlist = [];
  int _currentIndex = -1;

  bool get isPlaying => _player.state == PlayerState.playing;
  Duration get position => _currentPosition;
  Duration get duration => _cachedDuration ?? Duration.zero;

  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  Future<Duration> getDuration() async {
    return await _player.getDuration() ?? Duration.zero;
  }

  Future<void> playSong(Song song) async {
    try {
      if (song.audioUrl == null || song.audioUrl!.isEmpty) return;

      await _player.stop();

      currentSong = song;
      notifyListeners();

      await _player.play(
        UrlSource(song.audioUrl!),
        volume: 1.0,
        position: Duration.zero,
      );
    } catch (e) {
      print('Audio error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.resume();
    notifyListeners();
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  Future<void> stopAndClear() async {
    await _player.stop();
    currentSong = null;
    notifyListeners();
  }

  // Alias for stopAndClear
  Future<void> stop() async => stopAndClear();

  void setPlaylist(List<Song> songs) {
    _playlist = songs;
    _currentIndex = -1;
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playSong(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    _currentIndex =
        _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    await playSong(_playlist[_currentIndex]);
  }
}
