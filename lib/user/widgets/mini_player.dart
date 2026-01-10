import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  void initState() {
    super.initState();
    AudioPlayerService().addListener(_update);
  }

  @override
  void dispose() {
    AudioPlayerService().removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService();
    final song = service.currentSong;

    if (song == null) return const SizedBox();

    final progress = service.duration.inMilliseconds > 0
        ? service.position.inMilliseconds / service.duration.inMilliseconds
        : 0.0;

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Artwork
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: song.albumImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(song.albumImage!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.music_note, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Song Details & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  "${_formatDuration(service.position)} / ${_formatDuration(service.duration)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 3,
                ),
              ],
            ),
          ),

          // Play/Pause Button
          IconButton(
            icon: Icon(service.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: () => service.isPlaying ? service.pause() : service.resume(),
          ),

          // CLOSE BUTTON
          IconButton(
            icon: const Icon(Icons.close, color: Color.fromARGB(255, 157, 44, 44)),
            onPressed: () {
              // Calls your new method to stop audio and hide this UI
              service.stopAndClear();
            },
          ),
        ],
      ),
    );
  }
}