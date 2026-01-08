import 'package:flutter/material.dart';
import 'section_title.dart';
class RecentlyPlayedSection extends StatelessWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Recently Played'),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Song Name',
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
