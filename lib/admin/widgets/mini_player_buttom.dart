import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> {
  final AudioPlayerService playerService = AudioPlayerService();

  // Helper to format Duration into MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${twoDigits(seconds)}";
  }

  @override
  void initState() {
    super.initState();
    playerService.addListener(() {
      if (mounted) setState(() {});
    });
    playerService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = playerService.currentSong;
    if (currentSong == null) return const SizedBox.shrink();

    final bool isPlaying = playerService.player.state == PlayerState.playing;

    return Container(
      height: 125, // Increased slightly to fit labels comfortably
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border:
            const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: playerService.player.onPositionChanged,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: playerService.player.onDurationChanged,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  double max = duration.inMilliseconds.toDouble();
                  double value = position.inMilliseconds.toDouble();

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: Colors.green,
                        ),
                        child: Slider(
                          value: value.clamp(0.0, max > 0 ? max : 1.0),
                          max: max > 0 ? max : 1.0,
                          onChanged: (v) => playerService
                              .seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                      // Time Labels Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // --- CONTROLS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: () => playerService.playPrevious(),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.green,
                    size: 45,
                  ),
                  onPressed: () {
                    isPlaying ? playerService.pause() : playerService.resume();
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: () => playerService.playNext(),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    playerService.stopAndClear();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
