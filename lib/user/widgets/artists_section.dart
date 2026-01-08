import 'package:flutter/material.dart';
import 'section_title.dart';
class ArtistsSection extends StatelessWidget {
  const ArtistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Artists'),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => Column(
              children: [
             CircleAvatar(
  radius: 45,
  backgroundImage: NetworkImage(
    'https://i.pinimg.com/736x/04/3a/ac/043aacc7a1a49a1929936d6857f3962e.jpg',
  ),
),

                const SizedBox(height: 8),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Artist Name',
                    textAlign: TextAlign.center,
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
