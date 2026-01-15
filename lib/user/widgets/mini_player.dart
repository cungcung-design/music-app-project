import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import 'playing_song_page.dart';

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
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Artwork
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NowPlayingPage(
                        song: song,
                        playlist: service.playlist,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      song.albumImage ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Song Details & Progress Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_formatDuration(service.position)} / ${_formatDuration(service.duration)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // --- CONTROLS ---
              // Previous Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white, size: 28),
                onPressed: () => service.playPrevious(),
              ),

              // Play/Pause Button
              IconButton(
                iconSize: 32,
                icon: Icon(
                  service.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.greenAccent,
                ),
                onPressed: () =>
                    service.isPlaying ? service.pause() : service.resume(),
              ),

              // Next Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon:
                    const Icon(Icons.skip_next, color: Colors.white, size: 28),
                onPressed: () => service.playNext(),
              ),

              const SizedBox(width: 4),

              // Close Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => service.stopAndClear(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // --- PROGRESS BAR ---
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}
