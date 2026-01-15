import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';

class NowPlayingPage extends StatefulWidget {
  final Song song;
  const NowPlayingPage({super.key, required this.song});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late Song _currentSong;
  bool _isPlaying = false;
  bool _isFavorited = false;

  late AudioPlayerService _service;
  final DatabaseService _db = DatabaseService();
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _service = AudioPlayerService();
    _currentSong = widget.song;

    _checkFavoriteStatus();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Sync state with service
    if (_service.currentSong?.id == widget.song.id && _service.isPlaying) {
      _isPlaying = true;
      _rotationController.repeat();
    } else {
      _service.playSong(_currentSong);
      _isPlaying = true;
      _rotationController.repeat();
    }

    _service.addListener(_update);
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await _db.isFavorite(_currentSong.id);
    if (mounted) {
      setState(() => _isFavorited = status);
    }
  }

  Future<void> _toggleFavorite() async {
    final bool originalStatus = _isFavorited;

    // Update UI first (Optimistic)
    setState(() => _isFavorited = !_isFavorited);

    try {
      if (originalStatus) {
        await _db.removeFromFavorites(_currentSong.id);
      } else {
        await _db.addToFavorites(_currentSong.id);
      }
      _db.notifyFavoritesChanged();
    } catch (e) {
      setState(() => _isFavorited = originalStatus);
    }
  }

  void _update() {
    if (!mounted) return;

    setState(() {
      final newSong = _service.currentSong ?? _currentSong;

      if (_currentSong.id != newSong.id) {
        _currentSong = newSong;
        _checkFavoriteStatus();
      }

      _isPlaying = _service.isPlaying;

      // Handle Animation State
      if (_isPlaying) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        if (_rotationController.isAnimating) {
          _rotationController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _service.removeListener(_update);
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _service.pause();
    } else {
      _service.resume();
    }
  }

  String _format(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final position = _service.position;
    final duration = _service.duration;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // IMAGE ROTATION SECTION
          RotationTransition(
            turns: _rotationController,
            child: CircleAvatar(
              radius: 125,
              backgroundImage: _currentSong.albumImage != null
                  ? NetworkImage(_currentSong.albumImage!)
                  : null,
              backgroundColor: Colors.grey[700],
              child: _currentSong.albumImage == null
                  ? const Icon(Icons.music_note, size: 60, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(height: 32),

          // SONG INFO SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSong.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentSong.artistName ?? 'Unknown Artist',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.green : Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SLIDER SECTION
          Slider(
            value: position.inMilliseconds.toDouble().clamp(
                0.0,
                duration.inMilliseconds.toDouble() == 0
                    ? 1.0
                    : duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble() == 0
                ? 1.0
                : duration.inMilliseconds.toDouble(),
            activeColor: Colors.green,
            inactiveColor: Colors.grey[800],
            onChanged: (v) => _service.seek(Duration(milliseconds: v.toInt())),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(position),
                    style: const TextStyle(color: Colors.white70)),
                Text(_format(duration),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CONTROLS SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: _service.playPrevious,
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 80,
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.greenAccent,
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: _service.playNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
