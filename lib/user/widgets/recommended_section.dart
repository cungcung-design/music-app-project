import 'package:flutter/material.dart';
import 'section_title.dart';

class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary music data
    final List<Map<String, String>> musicData = [
      {"title": "Midnight City", "artist": "M83"},
      {"title": "Starboy", "artist": "The Weeknd"},
      {"title": "Blinding Lights", "artist": "The Weeknd"},
      {"title": "Levitating", "artist": "Dua Lipa"},
      {"title": "Stay", "artist": "The Kid LAROI"},
      {"title": "Save Your Tears", "artist": "The Weeknd"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Recommended for You'),
        const SizedBox(height: 12),
SizedBox(
  height: 170, 
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: musicData.length,
    separatorBuilder: (context, index) => const SizedBox(width: 12),
    itemBuilder: (context, index) {
      return Container(
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
                child: Image.network(
                  'https://i.pinimg.com/736x/b1/14/c7/b114c7b8b3c90ee6cb24880ca42c835e.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                musicData[index]["title"]!,
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
                musicData[index]["artist"]!,
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
      );
    },
  ),
),

      ],
    );
  }
}
