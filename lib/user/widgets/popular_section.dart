import 'package:flutter/material.dart';
import '../../models/song.dart';

class PopularSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Song, List<Song>) onSongTap;

  // New properties to track playback state
  final String? currentSongId;
  final bool isPlaying;

  const PopularSection({
    super.key,
    required this.songs,
    required this.onSongTap,
    this.currentSongId, // Pass this from your provider or parent state
    this.isPlaying = false, // Pass this to show if audio is actually playing
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Songs",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              // Check if this specific song is the one currently active
              final bool isCurrentActive = song.id == currentSongId;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onSongTap(song, songs),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.albumImage ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
                title: Text(
                  song.name,
                  style: TextStyle(
                   
                    color: isCurrentActive ? Colors.green : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  song.artistName ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: Icon(
                  isCurrentActive
                      ? (isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled)
                      : Icons.play_circle_outline,
                  color: isCurrentActive ? Colors.green : Colors.white38,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
