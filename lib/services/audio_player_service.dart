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
    // Also listen to position changes so the progress bar moves
    _player.onPositionChanged.listen((_) {
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Song? currentSong;

  bool get isPlaying => _player.state == PlayerState.playing;
  Duration get position => Duration.zero;
  Duration get duration =>
      Duration.zero; 
  Future<void> playSong(Song song) async {
    if (currentSong?.id != song.id) {
      await _player.setSourceUrl(song.audioUrl!);
      currentSong = song;
    }
    await _player.resume();
    notifyListeners();
  }

  void pause() {
    _player.pause();
    notifyListeners();
  }

  void resume() {
    _player.resume();
    notifyListeners();
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  // This is the key method for your close button
  Future<void> stopAndClear() async {
    await _player.stop();
    currentSong = null;
    notifyListeners();
  }
}
