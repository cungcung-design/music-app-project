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

    _player.onPositionChanged.listen((_) {
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Song? currentSong;

  bool get isPlaying => _player.state == PlayerState.playing;
  Duration get position => Duration.zero;
  Duration get duration => _cachedDuration ?? Duration.zero;
  Future<Duration> getDuration() async {
    return await _player.getDuration() ?? Duration.zero;
  }

  Future<void> playSong(Song song) async {
    try {
      if (currentSong?.id != song.id) {
        await _player.stop();
        await _player.setSourceUrl(song.audioUrl!);
        // Cache the duration
        _cachedDuration = await _player.getDuration();
        currentSong = song;
      }
      await _player.resume();
      notifyListeners();
    } catch (e) {
      print('Error playing song: $e');
      // Optionally, show a toast or handle the error
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

  // This is the key method for your close button
  Future<void> stopAndClear() async {
    await _player.stop();
    currentSong = null;
    notifyListeners();
  }
}
