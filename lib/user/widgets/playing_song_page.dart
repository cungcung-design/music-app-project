import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class NowPlayingPage extends StatefulWidget {
  final Song song;
  final List<Song>? playlist;
  const NowPlayingPage({super.key, required this.song, this.playlist});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late Song _currentSong;
  bool _isPlaying = false;
  late AudioPlayerService _service;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _service = AudioPlayerService();
    _currentSong = widget.song;

    _service.playSong(_currentSong);
    _isPlaying = true;

    _service.addListener(_update);

    // Rotation controller for album art
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Start rotation if playing
    if (_isPlaying) _rotationController.repeat();
  }

  @override
  void dispose() {
    _service.removeListener(_update);
    _rotationController.dispose();
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _service.pause();
      _rotationController.stop();
    } else {
      _service.resume();
      _rotationController.repeat();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _playSong(Song song) {
    _service.playSong(song);
    _rotationController.repeat();
    setState(() {
      _currentSong = song;
      _isPlaying = true;
    });
  }

  void _nextSong() {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    final index = widget.playlist!.indexWhere((s) => s.id == _currentSong.id);
    if (index == -1) return;
    final nextIndex = (index + 1) % widget.playlist!.length;
    _playSong(widget.playlist![nextIndex]);
  }

  void _previousSong() {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    final index = widget.playlist!.indexWhere((s) => s.id == _currentSong.id);
    if (index == -1) return;
    final prevIndex =
        (index - 1 + widget.playlist!.length) % widget.playlist!.length;
    _playSong(widget.playlist![prevIndex]);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final position = _service.position;
    final duration = _service.duration;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎵 Rotating Album Art
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 6.28319, // 2 * pi radians
                child: child,
              );
            },
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
              ),
              child: _currentSong.albumImage != null
                  ? ClipOval(
                      child: Image.network(
                        _currentSong.albumImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.music_note, color: Colors.white, size: 60),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            _currentSong.name,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_currentSong.artistName != null)
            Text(
              _currentSong.artistName!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 24),

          // Duration & Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Slider(
                  value: position.inMilliseconds
                      .toDouble()
                      .clamp(
                        0.0,
                        duration.inMilliseconds.toDouble() == 0
                            ? 1.0
                            : duration.inMilliseconds.toDouble(),
                      )
                      .toDouble(),
                  max: duration.inMilliseconds.toDouble() == 0
                      ? 1.0
                      : duration.inMilliseconds.toDouble(),
                  activeColor: Colors.greenAccent,
                  inactiveColor: Colors.grey[700],
                  onChanged: (value) {
                    _service.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Controls: Previous, Play/Pause, Next
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: _previousSong,
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.greenAccent,
                  size: 56,
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: _nextSong,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
