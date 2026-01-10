import 'package:flutter/material.dart';
import '../../models/song.dart';
import 'section_title.dart';

class RecommendedSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Song) onSongTap;

  const RecommendedSection({
    super.key,
    required this.songs,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SizedBox(); // nothing to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Recommended for You'),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              return GestureDetector(
                onTap: () => onSongTap(song),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: song.albumImage != null
                              ? Image.network(
                                  song.albumImage!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.music_note,
                                  color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          song.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          song.artistName ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
