import 'package:flutter/material.dart';
import '../../models/song.dart';

class RecentlyPlayedSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Song)? onSongTap;

  const RecentlyPlayedSection({
    super.key,
    required this.songs,
    this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Recently Played",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              return GestureDetector(
                onTap: () => onSongTap?.call(song),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[800],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.albumImage != null && song.albumImage!.isNotEmpty
                            ? Image.network(
                                song.albumImage!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 50,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        song.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
