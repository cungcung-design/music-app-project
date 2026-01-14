import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class MiniPlayerWidget extends StatefulWidget {
  final Song song;
  final AudioPlayerService playerService;
  final VoidCallback onStop;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MiniPlayerWidget({
    super.key,
    required this.song,
    required this.playerService,
    required this.onStop,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = widget.playerService.isPlaying;

    return Container(
      height: 115,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // --- SEEK BAR ---
          StreamBuilder<Duration>(
            stream: widget.playerService.player.onPositionChanged,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: widget.playerService.player.onDurationChanged,
                builder: (context, snapshotDuration) {
                  final duration = snapshotDuration.data ?? Duration.zero;
                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                    ),
                    child: Slider(
                      activeColor: Colors.green,
                      inactiveColor: Colors.white24,
                      value: position.inMilliseconds.toDouble().clamp(
                        0.0,
                        duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                      ),
                      max: duration.inMilliseconds.toDouble() > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (v) => widget.playerService.seek(
                        Duration(milliseconds: v.toInt()),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // --- CONTROLS ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      StreamBuilder<Duration>(
                        stream: widget.playerService.player.onPositionChanged,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream:
                                widget.playerService.player.onDurationChanged,
                            builder: (context, durationSnapshot) {
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;
                              return Text(
                                "${_formatDuration(position)} / ${_formatDuration(duration)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                      onPressed: widget.onPrevious,
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => isPlaying
                          ? widget.playerService.pause()
                          : widget.playerService.resume(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: widget.onNext,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: widget.onStop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
