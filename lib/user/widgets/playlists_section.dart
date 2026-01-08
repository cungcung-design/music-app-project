import 'package:flutter/material.dart';
import 'section_title.dart';

class PlaylistsSection extends StatelessWidget {
  const PlaylistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Popular Playlists'),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: ( context,index ) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[800],
                  ),
                  child: const Icon(Icons.queue_music, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Playlist Name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
